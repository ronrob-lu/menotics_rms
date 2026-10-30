-- rms_menotics: Ship Entity & Autonomous Navigation Mechanics

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")
local ship_nodes = dofile(minetest.get_modpath("rms_menotics") .. "/ship_nodes.lua")
local sinking = dofile(minetest.get_modpath("rms_menotics") .. "/sinking.lua")
local interactions = dofile(minetest.get_modpath("rms_menotics") .. "/interactions.lua")

local entity_mod = {}

-- Heading vectors (0: North +Z, 1: East +X, 2: South -Z, 3: West -X)
local HEADING_DIRS = {
	[0] = vector.new(0, 0, 1),
	[1] = vector.new(1, 0, 0),
	[2] = vector.new(0, 0, -1),
	[3] = vector.new(-1, 0, 0),
}

local HEADING_YAW = {
	[0] = 0,
	[1] = -math.pi / 2,
	[2] = math.pi,
	[3] = math.pi / 2,
}

-- Check if there is at least 5 blocks of open water under the hull along the ship length
-- Check if there is at least 3 blocks of open water under the hull along the ship length
function entity_mod.check_water_depth(center_pos, heading)
	local dir = HEADING_DIRS[heading % 4]
	local check_points = {-40, -20, 0, 20, 40}

	for _, offset_z in ipairs(check_points) do
		local check_center = vector.add(center_pos, vector.multiply(dir, offset_z))
		for depth = 1, 3 do
			local test_pos = vector.new(check_center.x, center_pos.y - depth, check_center.z)
			local node = minetest.get_node_or_nil(test_pos)
			if not node or not compat.is_water(node.name) then
				return false, "Insufficient water depth! Minimum 3 blocks of open water required under hull."
			end
		end
	end
	return true
end

-- Scan ahead for obstacles or iceberg hazards
function entity_mod.scan_ahead(center_pos, heading)
	local dir = HEADING_DIRS[heading % 4]
	local bow_offset = 52 -- Ahead of bow (50 blocks)
	local bow_pos = vector.add(center_pos, vector.multiply(dir, bow_offset))

	for lx = -7, 7 do
		for ly = 0, 5 do
			local side_vec
			if heading == 0 then side_vec = vector.new(lx, ly, 0)
			elseif heading == 1 then side_vec = vector.new(0, ly, -lx)
			elseif heading == 2 then side_vec = vector.new(-lx, ly, 0)
			elseif heading == 3 then side_vec = vector.new(0, ly, lx)
			end

			local scan_pos = vector.add(bow_pos, side_vec)
			local node = minetest.get_node_or_nil(scan_pos)

			if node and node.name ~= "air" and not compat.is_water(node.name) then
				if compat.is_ice_hazard(node.name) then
					return "iceberg", scan_pos, node.name
				else
					return "obstacle", scan_pos, node.name
				end
			end
		end
	end

	return "clear", nil, nil
end

-- Move all players standing on or inside the ship bounding box by move_vec
function entity_mod.move_standing_players(center_pos, heading, move_vec)
	local all_players = minetest.get_connected_players()
	for _, player in ipairs(all_players) do
		local ppos = player:get_pos()
		local rel = vector.subtract(ppos, center_pos)
		local local_off = ship_nodes.world_offset_to_local(rel, heading)

		if math.abs(local_off.x) <= 8 and local_off.y >= -1 and local_off.y <= 16 and math.abs(local_off.z) <= 52 then
			player:set_pos(vector.add(ppos, move_vec))
		end
	end
end

-- Global Node Hooks to track player modifications instantly without full-bounding box scanning
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	for _, obj in pairs(minetest.luaentities) do
		if obj and obj.name == "rms_menotics:ship_entity" and obj.object then
			local cpos = obj.object:get_pos()
			if cpos then
				local rel = vector.subtract(pos, cpos)
				local loff = ship_nodes.world_offset_to_local(rel, obj.heading or 0)
				if math.abs(loff.x) <= 8 and loff.y >= 0 and loff.y <= 15 and math.abs(loff.z) <= 50 then
					local key = loff.x .. "," .. loff.y .. "," .. loff.z
					local meta = minetest.get_meta(pos)
					obj.active_nodes[key] = {
						lx = loff.x, ly = loff.y, lz = loff.z,
						name = newnode.name,
						param1 = newnode.param1,
						param2 = newnode.param2,
						meta = meta and meta:to_table() or nil,
						is_base_deck = false,
					}
				end
			end
		end
	end
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
	for _, obj in pairs(minetest.luaentities) do
		if obj and obj.name == "rms_menotics:ship_entity" and obj.object then
			local cpos = obj.object:get_pos()
			if cpos then
				local rel = vector.subtract(pos, cpos)
				local loff = ship_nodes.world_offset_to_local(rel, obj.heading or 0)
				if math.abs(loff.x) <= 8 and loff.y >= 0 and loff.y <= 15 and math.abs(loff.z) <= 50 then
					local key = loff.x .. "," .. loff.y .. "," .. loff.z
					if obj.active_nodes[key] and not obj.active_nodes[key].is_base_deck then
						obj.active_nodes[key] = nil
					end
				end
			end
		end
	end
end)

-- Register Ship Entity
minetest.register_entity("rms_menotics:ship_entity", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "sprite",
		textures = {"colormap.png"},
		visual_size = {x = 0, y = 0, z = 0},
		static_save = true,
	},

	ship_id = nil,
	heading = 0,
	speed = 0.0,
	active_nodes = nil,
	displaced_water = nil,
	state = "manual",
	accum_step = 0.0,

	on_activate = function(self, staticdata, dtime_s)
		if staticdata and staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			if data then
				self.ship_id = data.ship_id
				self.heading = data.heading or 0
				self.speed = data.speed or 0.0
				self.active_nodes = data.active_nodes
				self.displaced_water = data.displaced_water or {}
				self.state = data.state or "manual"
				self.last_placed_pos = data.last_placed_pos
			end
		end

		if not self.active_nodes then
			self.active_nodes = ship_nodes.generate_default_ship_data()
		end

		if not self.last_placed_pos then
			self.last_placed_pos = self.object:get_pos()
		end

		self.object:set_yaw(HEADING_YAW[self.heading % 4])
	end,

	get_staticdata = function(self)
		local data = {
			ship_id = self.ship_id,
			heading = self.heading,
			speed = self.speed,
			active_nodes = self.active_nodes,
			displaced_water = self.displaced_water,
			state = self.state,
			last_placed_pos = self.last_placed_pos,
		}
		return minetest.serialize(data)
	end,

	on_step = function(self, dtime)
		if self.state == "sinking" then
			return
		end

		local pos = self.object:get_pos()
		if not pos then return end

		self.accum_step = self.accum_step + dtime

		-- Manual Cruising
		if self.accum_step >= 0.5 then
			local step_dtime = self.accum_step
			self.accum_step = 0.0

			if self.speed > 0 then
				local move_dist = self.speed * step_dtime
				local dir = HEADING_DIRS[self.heading % 4]
				local move_vec = vector.multiply(dir, move_dist)

				local status, hazard_pos, hazard_name = entity_mod.scan_ahead(pos, self.heading)
				local depth_ok, depth_err = entity_mod.check_water_depth(pos, self.heading)

				if status == "iceberg" then
					sinking.trigger_iceberg_collision(self, hazard_pos)
					return
				elseif status == "obstacle" or not depth_ok then
					self.speed = 0.0
					if self.object.set_velocity then
						self.object:set_velocity(vector.new(0, 0, 0))
					end
					compat.play_sound("rms_menotics_horn", {pos = pos, gain = 0.8, max_hear_distance = 80})
					return
				end

				-- Flood check mechanic: Check if water entered the bottom hull
				local flood_off = ship_nodes.local_to_world_offset(0, 1, 0, self.heading)
				local flood_pos = vector.add(pos, flood_off)
				local flood_node = minetest.get_node_or_nil(flood_pos)
				if flood_node and compat.is_water(flood_node.name) then
					sinking.trigger_iceberg_collision(self, flood_pos)
					return
				end

				-- Highly optimized movement: translate spatial active nodes only!
				local base_pos = self.last_placed_pos or pos
				local new_pos = vector.add(base_pos, move_vec)
				self.displaced_water = ship_nodes.move_ship_in_world(base_pos, new_pos, self.heading, self.active_nodes, self.displaced_water)
				self.last_placed_pos = new_pos

				self.object:set_pos(new_pos)
				if self.object.set_velocity then
					self.object:set_velocity(vector.multiply(move_vec, 1 / step_dtime))
				end
				entity_mod.move_standing_players(pos, self.heading, move_vec)
			else
				if self.object.set_velocity then
					self.object:set_velocity(vector.new(0, 0, 0))
				end
			end
		end
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if not puncher or not puncher:is_player() then return end

		local wielded = puncher:get_wielded_item()
		local item_name = wielded:get_name()

		local is_pickaxe = false
		if minetest.get_item_group(item_name, "pickaxe") > 0 or item_name:find("pick") then
			is_pickaxe = true
		end

		if is_pickaxe then
			interactions.dismantle_ship(self, puncher)
		else
			minetest.chat_send_player(puncher:get_player_name(), "[RMS Menotics] The hull is too strong! Use a pickaxe to dismantle the vessel.")
		end
	end,

	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then return end
		local wielded = clicker:get_wielded_item()

		if wielded:get_name():find("screwdriver") then
			interactions.rotate_ship(self, clicker)
		end
	end,
})

function entity_mod.on_steering_wheel_click(entity, clicker)
	if not entity or not entity.object or entity.state == "sinking" then return end
	local pos = entity.last_placed_pos or entity.object:get_pos()
	if not pos then return end
	local old_heading = entity.heading or 0
	local new_heading, rotated_nodes, new_displaced = ship_nodes.rotate_ship_cw(pos, old_heading, entity.active_nodes, entity.displaced_water)
	entity.heading = new_heading
	entity.active_nodes = rotated_nodes
	entity.displaced_water = new_displaced
	entity.object:set_yaw(HEADING_YAW[new_heading % 4])

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
		minetest.chat_send_player(clicker:get_player_name(), "[RMS Menotics] Heading changed.")
	end
end

function entity_mod.on_engine_control_click(entity, clicker)
	if not entity or not entity.object or entity.state == "sinking" then return end
	if not entity.speed then entity.speed = 0.0 end
	if entity.speed == 0.0 then
		entity.speed = 1.1
	elseif entity.speed == 1.1 then
		entity.speed = 2.2
	elseif entity.speed == 2.2 then
		entity.speed = 4.4
	else
		entity.speed = 0.0
	end
	if clicker and clicker:is_player() then
		minetest.chat_send_player(clicker:get_player_name(), "[RMS Menotics] Engine speed set to " .. entity.speed)
	end
end

function entity_mod.spawn_cruise_ship(pos, heading, placer)
	local spawn_pos = vector.new(pos.x, pos.y - 3, pos.z)
	local depth_ok, err = entity_mod.check_water_depth(spawn_pos, heading)
	if not depth_ok then
		return false, err
	end

	local ship_id = "ship_" .. os.time() .. "_" .. math.random(1000, 9999)
	local active_nodes = ship_nodes.generate_default_ship_data()

	local displaced = ship_nodes.place_ship_in_world(spawn_pos, heading, active_nodes, {})

	local ent_obj = minetest.add_entity(spawn_pos, "rms_menotics:ship_entity")
	if ent_obj then
		local luaent = ent_obj:get_luaentity()
		if luaent then
			luaent.ship_id = ship_id
			luaent.heading = heading
			luaent.speed = 0.0
			luaent.active_nodes = active_nodes
			luaent.displaced_water = displaced
			luaent.state = "manual"
			luaent.last_placed_pos = spawn_pos
			ent_obj:set_yaw(HEADING_YAW[heading % 4])
		end

		-- Persist ship position in mod storage for global /delete_menotics command
		local storage = minetest.get_mod_storage()
		if storage then
			local ships_data = storage:get_string("ships_list")
			local ships = (ships_data and ships_data ~= "") and minetest.deserialize(ships_data) or {}
			table.insert(ships, {id = ship_id, pos = spawn_pos, heading = heading})
			storage:set_string("ships_list", minetest.serialize(ships))
		end

		compat.play_sound("rms_menotics_horn", {pos = spawn_pos, gain = 1.0, max_hear_distance = 100})
		return true, nil
	end

	return false, "Could not add ship entity."
end

return entity_mod
