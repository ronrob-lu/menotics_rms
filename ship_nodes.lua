-- rms_menotics: Spatial Hash & Data Integrity Engine

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")

local ship_nodes = {}

-- Facedir rotation lookup table (90 degrees Clockwise)
ship_nodes.facedir_cw_map = {
	[0]=1, [1]=2, [2]=3, [3]=0,
	[4]=5, [5]=6, [6]=7, [7]=4,
	[8]=9, [9]=10, [10]=11, [11]=8,
	[12]=13, [13]=14, [14]=15, [15]=12,
	[16]=17, [17]=18, [18]=19, [19]=16,
	[20]=21, [21]=22, [22]=23, [23]=20,
}

-- Wallmounted rotation lookup table (90 degrees Clockwise)
ship_nodes.wallmounted_cw_map = {
	[0]=0, [1]=1, -- Floor and ceiling remain same
	[2]=4, -- North -> East
	[3]=5, -- South -> West
	[4]=3, -- East -> South
	[5]=2, -- West -> North
}

-- Convert ship local coordinate (lx, ly, lz) to world offset based on heading (0: N, 1: E, 2: S, 3: W)
function ship_nodes.local_to_world_offset(lx, ly, lz, heading)
	heading = heading % 4
	if heading == 0 then     -- North (+Z)
		return vector.new(lx, ly, lz)
	elseif heading == 1 then -- East (+X)
		return vector.new(lz, ly, -lx)
	elseif heading == 2 then -- South (-Z)
		return vector.new(-lx, ly, -lz)
	elseif heading == 3 then -- West (-X)
		return vector.new(-lz, ly, lx)
	end
	return vector.new(lx, ly, lz)
end

-- Convert world offset back to local ship coordinate (lx, ly, lz)
function ship_nodes.world_offset_to_local(off, heading)
	heading = heading % 4
	if heading == 0 then     -- North
		return vector.new(off.x, off.y, off.z)
	elseif heading == 1 then -- East
		return vector.new(-off.z, off.y, off.x)
	elseif heading == 2 then -- South
		return vector.new(-off.x, off.y, -off.z)
	elseif heading == 3 then -- West
		return vector.new(off.z, off.y, -off.x)
	end
	return vector.new(off.x, off.y, off.z)
end

-- Rotate node param2 if it uses facedir or wallmounted
function ship_nodes.rotate_param2_cw(nodename, param2)
	local def = minetest.registered_nodes[nodename]
	if not def then return param2 end

	if def.paramtype2 == "facedir" or def.paramtype2 == "colorfacedir" then
		local dir = param2 % 32
		local color = param2 - dir
		local new_dir = ship_nodes.facedir_cw_map[dir] or dir
		return color + new_dir
	elseif def.paramtype2 == "wallmounted" or def.paramtype2 == "colorwallmounted" then
		local dir = param2 % 8
		local color = param2 - dir
		local new_dir = ship_nodes.wallmounted_cw_map[dir] or dir
		return color + new_dir
	end

	return param2
end

-- Generate the 100x15x15 default ship structure into spatial hash map
function ship_nodes.generate_default_ship_data()
	local active_nodes = {}

	local function add_node(lx, ly, lz, name, param2)
		if name == "air" or name == "ignore" then return end
		local key = lx .. "," .. ly .. "," .. lz
		active_nodes[key] = {
			lx = lx, ly = ly, lz = lz,
			name = name,
			param1 = 0,
			param2 = param2 or 0,
			is_base_deck = true,
		}
	end

	for lz = -50, 49 do
		local max_w = 7
		if lz > 35 then
			max_w = math.max(1, math.floor(7 - (lz - 35) * 0.4))
		elseif lz < -40 then
			max_w = math.max(2, math.floor(7 - (-40 - lz) * 0.5))
		end

		for lx = -max_w, max_w do
			-- Lower Hull & Bottom (ly = 0 to 2)
			if ly == 0 then
				add_node(lx, 0, lz, "rms_menotics:hull")
			end

			-- Hull walls on sides
			if math.abs(lx) == max_w then
				for ly = 0, 7 do
					if ly == 4 and (lz % 4 == 0) then
						add_node(lx, ly, lz, "rms_menotics:glass") -- Portholes
					else
						add_node(lx, ly, lz, "rms_menotics:hull")
					end
				end
			end

			-- Deck Floors
			add_node(lx, 2, lz, "rms_menotics:deck") -- Lower deck floor
			add_node(lx, 7, lz, "rms_menotics:deck") -- Mid deck floor / Promenade base
			add_node(lx, 8, lz, "rms_menotics:deck") -- Promenade floor

			-- Promenade Glass Enclosure (ly = 8)
			if math.abs(lx) == max_w then
				add_node(lx, 8, lz, "rms_menotics:glass")
			end

			-- Top Sun Deck (ly = 9)
			if lz >= -45 and lz <= 40 then
				add_node(lx, 9, lz, "rms_menotics:deck")

				-- Outer Railings on Sun Deck (ly = 10)
				if math.abs(lx) == max_w or lz == -45 or lz == 40 then
					add_node(lx, 10, lz, "rms_menotics:railing")
				end

				-- Outdoor Swimming Pool (lz between 10 and 20, lx between -3 and 3)
				if lz >= 10 and lz <= 20 and math.abs(lx) <= 3 then
					if math.abs(lx) == 3 or lz == 10 or lz == 20 then
						add_node(lx, 9, lz, "rms_menotics:hull") -- Pool border
					else
						add_node(lx, 9, lz, "rms_menotics:pool_water") -- Pool water
					end
				end

				-- Sun Deck Chairs
				if (lz % 6 == 0) and math.abs(lx) == max_w - 1 then
					local facedir = (lx < 0) and 3 or 1
					add_node(lx, 10, lz, "rms_menotics:chair", facedir)
				end
			end

			-- Interior Staircases / Ladders (at lz = -20, 0, +20)
			if (lz == -20 or lz == 0 or lz == 20) and lx == 0 then
				for ly = 3, 9 do
					if minetest.registered_nodes["default:ladder_wood"] then
						add_node(lx, ly, lz, "default:ladder_wood", 2)
					elseif minetest.registered_nodes["mcl_core:ladder"] then
						add_node(lx, ly, lz, "mcl_core:ladder", 2)
					else
						add_node(lx, ly, lz, "rms_menotics:deck")
					end
				end
			end
		end

		-- Command Bridge / Navigation Superstructure on Upper Forward Deck (lz between 28 and 36)
		if lz >= 28 and lz <= 36 then
			local bw = math.min(5, max_w - 1)
			for lx = -bw, bw do
				for ly = 10, 12 do
					if ly == 12 then
						-- Bridge Roof
						add_node(lx, ly, lz, "rms_menotics:hull")
					elseif ly == 11 then
						-- Panoramic Glass Windows on front (lz=36), sides (lx=±bw), and rear (lz=28)
						if math.abs(lx) == bw or lz == 36 or lz == 28 then
							add_node(lx, ly, lz, "rms_menotics:glass")
						end
					elseif ly == 10 then
						-- Bridge lower walls and front windows
						if lz == 36 or math.abs(lx) == bw then
							add_node(lx, ly, lz, "rms_menotics:glass")
						elseif lz == 28 then
							add_node(lx, ly, lz, "rms_menotics:hull")
						end
					end
				end
			end

			-- Bridge Command Console & Steering Station inside (lz = 35)
			for lx = -3, 3 do
				add_node(lx, 10, 35, "rms_menotics:railing")
			end
		end

		-- Funnels / Chimneys on Top Deck (lz = -10, lz = 5)
		if (lz >= -12 and lz <= -8) or (lz >= 3 and lz <= 7) then
			for lx = -2, 2 do
				for ly = 10, 13 do
					if math.abs(lx) == 2 or lz == -12 or lz == -8 or lz == 3 or lz == 7 or ly == 13 then
						add_node(lx, ly, lz, "rms_menotics:hull")
					end
				end
			end
		end
	end

	return active_nodes
end

-- Place or update active nodes in the world, maintaining displaced water state
function ship_nodes.place_ship_in_world(ship_center_pos, heading, active_nodes, displaced_water)
	displaced_water = displaced_water or {}
	local new_displaced = {}

	-- Fast spatial iteration: only loop through active nodes!
	for _, nd in pairs(active_nodes) do
		local off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, heading)
		local world_pos = vector.add(ship_center_pos, off)
		local current_world_node = minetest.get_node_or_nil(world_pos)

		-- Record original displaced water if present
		local wkey = world_pos.x .. "," .. world_pos.y .. "," .. world_pos.z
		if current_world_node and compat.is_water(current_world_node.name) then
			new_displaced[wkey] = current_world_node.name
		elseif displaced_water[wkey] then
			new_displaced[wkey] = displaced_water[wkey]
		end

		-- Set node in world
		minetest.set_node(world_pos, {
			name = nd.name,
			param1 = nd.param1,
			param2 = nd.param2,
		})

		-- Restore metadata and inventories
		if nd.meta then
			local meta = minetest.get_meta(world_pos)
			if meta then
				meta:from_table(nd.meta)
			end
		end
	end

	-- Interior watertight cavity: clear water entries inside hull boundaries
	for lz = -48, 47 do
		for ly = 1, 8 do
			for lx = -6, 6 do
				local key = lx .. "," .. ly .. "," .. lz
				if not active_nodes[key] then
					local off = ship_nodes.local_to_world_offset(lx, ly, lz, heading)
					local world_pos = vector.add(ship_center_pos, off)
					local current_node = minetest.get_node_or_nil(world_pos)

					if current_node then
						local wkey = world_pos.x .. "," .. world_pos.y .. "," .. world_pos.z
						if compat.is_water(current_node.name) then
							new_displaced[wkey] = current_node.name
							minetest.set_node(world_pos, {name = "air"})
						end
					end
				end
			end
		end
	end

	return new_displaced
end

-- Clear ship from old position in world, restoring displaced water
function ship_nodes.clear_ship_from_world(ship_center_pos, heading, active_nodes, displaced_water)
	displaced_water = displaced_water or {}

	-- Clear active nodes
	for _, nd in pairs(active_nodes) do
		local off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, heading)
		local world_pos = vector.add(ship_center_pos, off)
		local wkey = world_pos.x .. "," .. world_pos.y .. "," .. world_pos.z

		local restore_node = displaced_water[wkey] or "air"
		minetest.set_node(world_pos, {name = restore_node})
	end

	-- Clear interior air cavities
	for lz = -48, 47 do
		for ly = 1, 8 do
			for lx = -6, 6 do
				local off = ship_nodes.local_to_world_offset(lx, ly, lz, heading)
				local world_pos = vector.add(ship_center_pos, off)
				local wkey = world_pos.x .. "," .. world_pos.y .. "," .. world_pos.z

				local restore_node = displaced_water[wkey] or "air"
				if minetest.get_node(world_pos).name == "air" and restore_node ~= "air" then
					minetest.set_node(world_pos, {name = restore_node})
				end
			end
		end
	end
end

-- Fast translation from old_pos to new_pos (only iterates active_nodes!)
function ship_nodes.move_ship_in_world(old_pos, new_pos, heading, active_nodes, displaced_water)
	ship_nodes.clear_ship_from_world(old_pos, heading, active_nodes, displaced_water)
	local new_displaced = ship_nodes.place_ship_in_world(new_pos, heading, active_nodes, {})
	return new_displaced
end

-- Rotate ship 90 degrees clockwise (for screwdriver interaction)
function ship_nodes.rotate_ship_cw(ship_center_pos, old_heading, active_nodes, displaced_water)
	ship_nodes.clear_ship_from_world(ship_center_pos, old_heading, active_nodes, displaced_water)

	local new_heading = (old_heading + 1) % 4
	local rotated_nodes = {}

	for key, nd in pairs(active_nodes) do
		local new_param2 = ship_nodes.rotate_param2_cw(nd.name, nd.param2)
		rotated_nodes[key] = {
			lx = nd.lx, ly = nd.ly, lz = nd.lz,
			name = nd.name,
			param1 = nd.param1,
			param2 = new_param2,
			meta = nd.meta,
			is_base_deck = nd.is_base_deck,
		}
	end

	local new_displaced = ship_nodes.place_ship_in_world(ship_center_pos, new_heading, rotated_nodes, {})
	return new_heading, rotated_nodes, new_displaced
end

return ship_nodes
