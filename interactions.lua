-- rms_menotics: Player Tool Interactions (Screwdriver Rotation & Pickaxe Dismantling)

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")
local ship_nodes = dofile(minetest.get_modpath("rms_menotics") .. "/ship_nodes.lua")

local interactions = {}

-- Screwdriver Rotation: Right-click with screwdriver rotates ship 90 degrees clockwise
function interactions.rotate_ship(entity, clicker)
	if not entity or not entity.object or entity.state == "sinking" then return end

	local pos = entity.last_placed_pos or entity.object:get_pos()
	if not pos then return end

	local old_heading = entity.heading or 0
	local new_heading, rotated_nodes, new_displaced = ship_nodes.rotate_ship_cw(pos, old_heading, entity.active_nodes, entity.displaced_water)

	entity.heading = new_heading
	entity.active_nodes = rotated_nodes
	entity.displaced_water = new_displaced

	local HEADING_YAW = {
		[0] = 0,
		[1] = -math.pi / 2,
		[2] = math.pi,
		[3] = math.pi / 2,
	}
	entity.object:set_yaw(HEADING_YAW[new_heading % 4])

	-- Rotate standing players accordingly
	local all_players = minetest.get_connected_players()
	for _, player in ipairs(all_players) do
		local ppos = player:get_pos()
		local rel = vector.subtract(ppos, pos)
		local local_off = ship_nodes.world_offset_to_local(rel, old_heading)

		if math.abs(local_off.x) <= 8 and local_off.y >= -1 and local_off.y <= 16 and math.abs(local_off.z) <= 52 then
			local new_rel = ship_nodes.local_to_world_offset(local_off.x, local_off.y, local_off.z, new_heading)
			player:set_pos(vector.add(pos, new_rel))
		end
	end

	compat.play_sound("rms_menotics_splash", {pos = pos, gain = 0.5})
	if clicker and clicker:is_player() then
		minetest.chat_send_player(clicker:get_player_name(), "[RMS Menotics] Rotated vessel 90° clockwise.")
	end
end

-- Pickaxe Dismantling: Safely dismantle ship, return ship item, and drop cargo/chest contents
function interactions.dismantle_ship(entity, puncher)
	if not entity or not entity.object or entity.state == "sinking" then return end

	local pos = entity.last_placed_pos or entity.object:get_pos()
	if not pos then return end

	-- Drop inventory contents / custom items
	for key, nd in pairs(entity.active_nodes) do
		if nd.meta and nd.meta.inventory then
			for listname, list in pairs(nd.meta.inventory) do
				for _, itemstack_data in ipairs(list) do
					if itemstack_data and not itemstack_data:is_empty() then
						local off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, entity.heading)
						local drop_pos = vector.add(pos, off)
						minetest.add_item(drop_pos, itemstack_data)
					end
				end
			end
		end

		if not nd.is_base_deck and nd.name ~= "rms_menotics:deck" and nd.name ~= "rms_menotics:hull" and
		   nd.name ~= "rms_menotics:railing" and nd.name ~= "rms_menotics:glass" and
		   nd.name ~= "rms_menotics:chair" and nd.name ~= "rms_menotics:pool_water" then
			local off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, entity.heading)
			local drop_pos = vector.add(pos, off)
			minetest.add_item(drop_pos, ItemStack(nd.name))
		end
	end

	-- Drop RMS Menotics cruise ship item
	minetest.add_item(pos, ItemStack("rms_menotics:cruise_ship"))

	-- Clear ship blocks from world and restore ocean water
	ship_nodes.clear_ship_from_world(pos, entity.heading, entity.active_nodes, entity.displaced_water)

	-- Play dismantling audio sound
	compat.play_sound("rms_menotics_splash", {pos = pos, gain = 1.0})

	if puncher and puncher:is_player() then
		minetest.chat_send_player(puncher:get_player_name(), "[RMS Menotics] RMS Menotics successfully dismantled. Cargo safely dropped.")
	end

	-- Remove entity object
	entity.object:remove()
end

return interactions
