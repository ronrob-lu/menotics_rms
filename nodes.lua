-- rms_menotics: Node Definitions & Crafting Recipes

local compat = dofile(minetest.get_modpath("rms_menotics") .. "/compat.lua")

-- Register Deck Node
minetest.register_node("rms_menotics:deck", {
	description = "RMS Menotics Ship Deck",
	tiles = {"rms_menotics_deck.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 1, ship_deck = 1},
	sounds = compat.get_sounds("wood"),
	is_ground_content = false,
})

-- Register Railing Node
minetest.register_node("rms_menotics:railing", {
	description = "RMS Menotics Ship Railing",
	drawtype = "fencelike",
	tiles = {"rms_menotics_railing.png"},
	inventory_image = "rms_menotics_railing.png",
	wield_image = "rms_menotics_railing.png",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
	},
	collision_box = {
		type = "fixed",
		fixed = {-1/2, -1/2, -1/2, 1/2, 1/2, 1/2},
	},
	groups = {snappy = 2, choppy = 2, oddly_breakable_by_hand = 2, ship_railing = 1},
	sounds = compat.get_sounds("wood"),
})

-- Register Hull Steel Node
minetest.register_node("rms_menotics:hull", {
	description = "RMS Menotics Ship Hull",
	tiles = {"rms_menotics_hull.png"},
	groups = {cracky = 1, level = 2, ship_hull = 1},
	sounds = compat.get_sounds("metal"),
	is_ground_content = false,
})

-- Register Glass Promenade Window Node
minetest.register_node("rms_menotics:glass", {
	description = "RMS Menotics Promenade Glass",
	drawtype = "glasslike",
	tiles = {"rms_menotics_glass.png"},
	use_texture_alpha = "clip",
	paramtype = "light",
	sunlight_propagates = true,
	groups = {snappy = 2, cracky = 3, oddly_breakable_by_hand = 3, ship_glass = 1},
	sounds = compat.get_sounds("glass"),
	is_ground_content = false,
})

-- Register Deck Chair
minetest.register_node("rms_menotics:chair", {
	description = "RMS Menotics Deck Chair",
	drawtype = "nodebox",
	tiles = {"rms_menotics_chair.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4, -0.5, -0.4, 0.4, -0.1, 0.4},
			{-0.4, -0.1, 0.2, 0.4, 0.4, 0.4},
			{-0.4, -0.5, -0.4, -0.3, 0.1, -0.3},
			{0.3, -0.5, -0.4, 0.4, 0.1, -0.3},
		}
	},
	groups = {snappy = 2, choppy = 2, ship_furniture = 1},
	sounds = compat.get_sounds("wood"),
	is_ground_content = false,
})

-- Register Steering Wheel Node
minetest.register_node("rms_menotics:steering_wheel", {
	description = "RMS Menotics Steering Wheel",
	drawtype = "nodebox",
	tiles = {"rms_menotics_hull.png"}, -- reuse a suitable texture
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2, -0.5, -0.2, 0.2, 0.5, 0.2},
			{-0.4, 0.1, -0.4, 0.4, 0.5, 0.4},
		}
	},
	groups = {snappy = 2, choppy = 2, ship_furniture = 1},
	sounds = compat.get_sounds("wood"),
	is_ground_content = false,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker or not clicker:is_player() then return itemstack end
		local handled = false
		for _, obj in pairs(minetest.luaentities) do
			if obj and obj.name == "rms_menotics:ship_entity" and obj.object then
				local cpos = obj.object:get_pos()
				if cpos and vector.distance(pos, cpos) < 60 then
					if rms_menotics and rms_menotics.entity then
						rms_menotics.entity.on_steering_wheel_click(obj, clicker)
						handled = true
						break
					end
				end
			end
		end
		if not handled then
			minetest.chat_send_player(clicker:get_player_name(), "[RMS Menotics] Steering wheel is not connected to a functioning ship.")
		end
		return itemstack
	end,
})

-- Register Engine Control Node
minetest.register_node("rms_menotics:engine_control", {
	description = "RMS Menotics Engine Telegraph",
	drawtype = "nodebox",
	tiles = {"rms_menotics_hull.png"}, -- reuse a suitable texture
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.2, -0.5, -0.2, 0.2, 0.3, 0.2},
			{-0.3, 0.3, -0.1, 0.3, 0.5, 0.1},
		}
	},
	groups = {snappy = 2, choppy = 2, ship_furniture = 1},
	sounds = compat.get_sounds("metal"),
	is_ground_content = false,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not clicker or not clicker:is_player() then return itemstack end
		local handled = false
		for _, obj in pairs(minetest.luaentities) do
			if obj and obj.name == "rms_menotics:ship_entity" and obj.object then
				local cpos = obj.object:get_pos()
				if cpos and vector.distance(pos, cpos) < 60 then
					if rms_menotics and rms_menotics.entity then
						rms_menotics.entity.on_engine_control_click(obj, clicker)
						handled = true
						break
					end
				end
			end
		end
		if not handled then
			minetest.chat_send_player(clicker:get_player_name(), "[RMS Menotics] Engine telegraph is not connected to a functioning ship.")
		end
		return itemstack
	end,
})

-- Register RMS Menotics Cruise Ship Item
minetest.register_craftitem("rms_menotics:cruise_ship", {
	description = "RMS Menotics Cruise Ship",
	inventory_image = "rms_menotics_cruise_ship.png",
	wield_image = "rms_menotics_cruise_ship.png",
	stack_max = 1,
	liquids_pointable = true,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		local pos = pointed_thing.above
		local under = pointed_thing.under
		local under_node = minetest.get_node(under)

		if not compat.is_water(under_node.name) and not compat.is_water(minetest.get_node(pos).name) then
			if placer and placer:is_player() then
				minetest.chat_send_player(placer:get_player_name(), "[RMS Menotics] The cruise ship must be placed in water!")
			end
			return itemstack
		end

		local dir = placer and placer:get_look_horizontal() or 0
		local heading_dir = math.floor((dir / (math.pi / 2)) + 0.5) % 4

		local success, err = rms_menotics.entity.spawn_cruise_ship(pos, heading_dir, placer)
		if success then
			if not minetest.settings:get_bool("creative_mode") then
				itemstack:take_item()
			end
		elseif err and placer and placer:is_player() then
			minetest.chat_send_player(placer:get_player_name(), "[RMS Menotics] Deployment failed: " .. err)
		end

		return itemstack
	end,
})

-- Crafting Recipe:
-- Requirements: 10x Steel/Iron Blocks, 5x Coal Blocks, 20x Wood Planks, 10x Glass, 5x Gold Ingots
minetest.register_craft({
	output = "rms_menotics:cruise_ship 1",
	type = "shapeless",
	recipe = {
		compat.STEEL_BLOCK .. " 10",
		compat.COAL_BLOCK .. " 5",
		compat.WOOD_PLANK .. " 20",
		compat.GLASS .. " 10",
		compat.GOLD_INGOT .. " 5",
	}
})

return compat
