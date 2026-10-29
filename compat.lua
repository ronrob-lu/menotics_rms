-- rms_menotics: Cross-Game Compatibility API

local compat = {}

-- Detect game environment
compat.is_mcl = minetest.get_modpath("mcl_core") ~= nil
compat.is_mtg = minetest.get_modpath("default") ~= nil

-- Standard node lookup based on game
if compat.is_mcl then
	compat.STEEL_BLOCK = "mcl_core:ironblock"
	compat.COAL_BLOCK  = "mcl_core:coalblock"
	compat.WOOD_PLANK  = "mcl_core:wood"
	compat.GLASS       = "mcl_core:glass"
	compat.GOLD_INGOT  = "mcl_core:gold_ingot"
	compat.WATER_SRC   = "mcl_core:water_source"
	compat.WATER_FLOW  = "mcl_core:water_flowing"
	compat.AIR         = "air"
else
	compat.STEEL_BLOCK = "default:steelblock"
	compat.COAL_BLOCK  = "default:coalblock"
	compat.WOOD_PLANK  = "default:wood"
	compat.GLASS       = "default:glass"
	compat.GOLD_INGOT  = "default:gold_ingot"
	compat.WATER_SRC   = "default:water_source"
	compat.WATER_FLOW  = "default:water_flowing"
	compat.AIR         = "air"
end

-- Sound fallbacks
function compat.get_sounds(sound_type)
	if compat.is_mcl and minetest.get_modpath("mcl_sounds") and _G.mcl_sounds then
		if sound_type == "wood" and mcl_sounds.node_sound_wood_defaults then
			return mcl_sounds.node_sound_wood_defaults()
		elseif sound_type == "metal" and mcl_sounds.node_sound_metal_defaults then
			return mcl_sounds.node_sound_metal_defaults()
		elseif sound_type == "glass" and mcl_sounds.node_sound_glass_defaults then
			return mcl_sounds.node_sound_glass_defaults()
		end
	elseif compat.is_mtg and minetest.get_modpath("default") and _G.default then
		if sound_type == "wood" and default.node_sound_wood_defaults then
			return default.node_sound_wood_defaults()
		elseif sound_type == "metal" and default.node_sound_metal_defaults then
			return default.node_sound_metal_defaults()
		elseif sound_type == "glass" and default.node_sound_glass_defaults then
			return default.node_sound_glass_defaults()
		end
	end
	return {}
end

-- Helper to check if a node is any kind of water
function compat.is_water(nodename)
	if nodename == compat.WATER_SRC or nodename == compat.WATER_FLOW then
		return true
	end
	if nodename == "default:water_source" or nodename == "default:water_flowing" or
	   nodename == "mcl_core:water_source" or nodename == "mcl_core:water_flowing" or
	   nodename == "mcl_core:river_water_source" or nodename == "mcl_core:river_water_flowing" or
	   nodename == "default:river_water_source" or nodename == "default:river_water_flowing" then
		return true
	end
	local def = minetest.registered_nodes[nodename]
	if def and def.groups and (def.groups.water or def.groups.liquid) then
		return true
	end
	return false
end

-- Helper to check if a node is an iceberg hazard (ice / packed ice / blue ice / snow)
function compat.is_ice_hazard(nodename)
	if nodename == "default:ice" or nodename == "default:cave_ice" or
	   nodename == "mcl_core:ice" or nodename == "mcl_core:packed_ice" or
	   nodename == "mcl_core:blue_ice" or nodename == "mcl_core:frosted_ice" or
	   nodename == "default:snowblock" or nodename == "mcl_core:snowblock" or
	   nodename == "mcl_core:snow" or nodename == "default:snow" then
		return true
	end
	local def = minetest.registered_nodes[nodename]
	if def and def.groups and (def.groups.ice or def.groups.snowy or def.groups.snow) then
		return true
	end
	return false
end

-- Play custom or fallback sound
function compat.play_sound(sound_name, spec)
	spec = spec or {}
	if minetest.sound_play then
		return minetest.sound_play(sound_name, spec, true)
	end
end

return compat
