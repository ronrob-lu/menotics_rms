-- rms_menotics: Global Management Admin Commands

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")
local ship_nodes = dofile(minetest.get_modpath("rms_menotics") .. "/ship_nodes.lua")

local commands = {}

local function clear_all_ships(name)
	local storage = minetest.get_mod_storage()
	local ships_data = storage and storage:get_string("ships_list") or ""
	local ships = (ships_data and ships_data ~= "") and minetest.deserialize(ships_data) or {}
	local count = 0

	-- 1. Process persisted ships from mod storage
	for idx, ship_entry in ipairs(ships) do
		local pos = ship_entry.pos
		local heading = ship_entry.heading or 0

		if pos then
			-- Force load mapblocks in a 60-block radius
			if minetest.emerge_area then
				minetest.emerge_area(
					vector.add(pos, vector.new(-60, -10, -60)),
					vector.add(pos, vector.new(60, 20, 60)),
					function(blockpos, action, calls_remaining, calls_made)
						if calls_remaining == 0 then
							local active_nodes = ship_nodes.generate_default_ship_data()
							ship_nodes.clear_ship_from_world(pos, heading, active_nodes, {})
						end
					end
				)
			else
				local active_nodes = ship_nodes.generate_default_ship_data()
				ship_nodes.clear_ship_from_world(pos, heading, active_nodes, {})
			end
			count = count + 1
		end
	end

	-- 2. Process active loaded luaentities
	for _, obj in pairs(minetest.luaentities) do
		if obj and obj.name == "rms_menotics:ship_entity" and obj.object then
			local pos = obj.object:get_pos()
			if pos then
				if obj.active_nodes then
					ship_nodes.clear_ship_from_world(pos, obj.heading or 0, obj.active_nodes, obj.displaced_water or {})
				end
				obj.object:remove()
			end
		end
	end

	-- Clear persistent storage
	if storage then
		storage:set_string("ships_list", minetest.serialize({}))
	end

	local msg = "[RMS Menotics Admin] Cleared all (" .. count .. ") RMS Menotics cruise ship(s) from persistent storage and loaded mapblocks."
	if name then
		minetest.chat_send_player(name, msg)
	else
		minetest.log("action", msg)
	end
end

-- Register Chat Command: /delete_menotics (with aliases /clear_ships, /delete_cruise)
minetest.register_chatcommand("delete_menotics", {
	description = "Safely deletes all RMS Menotics cruise ships, restores natural ocean water, and drops stored items.",
	privs = {server = true},
	func = function(name, param)
		clear_all_ships(name)
		return true
	end,
})

minetest.register_chatcommand("clear_ships", {
	description = "Alias for /delete_menotics",
	privs = {server = true},
	func = function(name, param)
		clear_all_ships(name)
		return true
	end,
})

minetest.register_chatcommand("delete_cruise", {
	description = "Alias for /delete_menotics",
	privs = {server = true},
	func = function(name, param)
		clear_all_ships(name)
		return true
	end,
})

return commands
