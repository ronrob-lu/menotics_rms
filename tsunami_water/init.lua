-- Tsunami Water Mod (`tsunami_water`)
-- Main Initialization File

-- Register Pool Water Node
minetest.register_node("tsunami_water:pool_water", {
	description = "Tsunami Pool Water",
	drawtype = "liquid",
	tiles = {"tsunami_water_pool_water.png"},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "tsunami_water:pool_water",
	liquid_alternative_source = "tsunami_water:pool_water",
	liquid_viscosity = 1,
	post_effect_color = {a = 120, r = 30, g = 120, b = 200},
	groups = {water = 3, liquid = 3, cools_lava = 1},
})

minetest.log("action", "[tsunami_water] Tsunami Water Mod loaded successfully!")