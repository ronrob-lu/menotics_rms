-- rms_menotics: Iceberg Collision & Catastrophic Sinking Engine

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")
local ship_nodes = dofile(minetest.get_modpath("rms_menotics") .. "/ship_nodes.lua")

local sinking = {}

function sinking.trigger_iceberg_collision(entity, hazard_pos)
	if not entity or not entity.object or entity.state == "sinking" then return end

	entity.state = "sinking"
	local pos = entity.object:get_pos()
	if not pos then return end

	minetest.chat_send_all("[RMS Menotics ALERT] CATASTROPHIC ICEBERG COLLISION! The RMS Menotics hull is breached!")
	compat.play_sound("rms_menotics_sink", {pos = pos, gain = 1.0, max_hear_distance = 150})

	-- 1. Spawn player-placed custom blocks as physical gravity-affected falling nodes
	for key, nd in pairs(entity.active_nodes) do
		local off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, entity.heading)
		local node_pos = vector.add(pos, off)

		if not nd.is_base_deck and nd.name ~= "rms_menotics:deck" and nd.name ~= "rms_menotics:hull" and
		   nd.name ~= "rms_menotics:railing" and nd.name ~= "rms_menotics:glass" and
		   nd.name ~= "rms_menotics:chair" then

			if nd.meta and nd.meta.inventory then
				for listname, list in pairs(nd.meta.inventory) do
					for _, itemstack_data in ipairs(list) do
						if itemstack_data and not itemstack_data:is_empty() then
							minetest.add_item(node_pos, itemstack_data)
						end
					end
				end
			end

			if minetest.spawn_falling_node then
				minetest.set_node(node_pos, {name = nd.name, param1 = nd.param1, param2 = nd.param2})
				minetest.spawn_falling_node(node_pos)
			else
				minetest.add_item(node_pos, ItemStack(nd.name))
				minetest.set_node(node_pos, {name = "air"})
			end
		end
	end

	-- 2. Immediately remove physical ship node structure and flood water to prevent floating ghost blocks!
	ship_nodes.clear_ship_from_world(pos, entity.heading, entity.active_nodes, entity.displaced_water)

	-- Flood hull bounding region with ocean water
	for lz = -48, 47 do
		for ly = 0, 8 do
			for lx = -6, 6 do
				local off = ship_nodes.local_to_world_offset(lx, ly, lz, entity.heading)
				local fill_pos = vector.add(pos, off)
				local cur_node = minetest.get_node(fill_pos)

				if cur_node.name == "air" or cur_node.name == "rms_menotics:glass" then
					minetest.set_node(fill_pos, {name = compat.WATER_SRC})
				end
			end
		end
	end

	-- 3. Spawn animated bubble trails and smoke wakes using particle spawners
	if minetest.add_particlespawner then
		minetest.add_particlespawner({
			amount = 300,
			time = 15,
			minpos = vector.add(pos, vector.new(-10, -2, -40)),
			maxpos = vector.add(pos, vector.new(10, 5, 40)),
			minvel = vector.new(-1, 1, -1),
			maxvel = vector.new(1, 3, 1),
			minacc = vector.new(0, 0.5, 0),
			maxacc = vector.new(0, 1.5, 0),
			minexptime = 2,
			maxexptime = 5,
			minsize = 2,
			maxsize = 5,
			collisiondetection = false,
			texture = "rms_menotics_glass.png",
		})
	end

	-- 4. Animate entity slowly tilting and sinking visual mesh over 15 seconds
	local sink_time = 0
	local total_sink_duration = 15.0

	local function sink_step()
		sink_time = sink_time + 1.0
		if not entity.object or not entity.object:get_pos() then return end

		local cur_pos = entity.object:get_pos()
		local next_pos = vector.new(cur_pos.x, cur_pos.y - 0.6, cur_pos.z)
		entity.object:set_pos(next_pos)

		if math.floor(sink_time) % 4 == 0 then
			compat.play_sound("rms_menotics_sink", {pos = next_pos, gain = 0.8})
		end

		if sink_time < total_sink_duration then
			minetest.after(1.0, sink_step)
		else
			entity.object:remove()
			minetest.chat_send_all("[RMS Menotics] The RMS Menotics has plunged into the ocean depths.")
		end
	end

	minetest.after(1.0, sink_step)
end

return sinking
