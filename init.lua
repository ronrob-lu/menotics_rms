-- RMS Menotics Cruise Ship Mod (`rms_menotics`)
-- Main Initialization File

local modpath = minetest.get_modpath("rms_menotics")

-- Load compatibility API
local compat = dofile(modpath .. "/compat.lua")

-- Load spatial hash & block integrity engine
local ship_nodes = dofile(modpath .. "/ship_nodes.lua")

-- Load player tool interactions (screwdriver rotation & pickaxe dismantling)
local interactions = dofile(modpath .. "/interactions.lua")

-- Load sinking engine (iceberg collisions)
local sinking = dofile(modpath .. "/sinking.lua")

-- Load ship entity and navigation engine
rms_menotics = rms_menotics or {}
rms_menotics.entity = dofile(modpath .. "/entity.lua")

-- Load node definitions & craft items
rms_menotics.nodes = dofile(modpath .. "/nodes.lua")

-- Load global admin commands
rms_menotics.commands = dofile(modpath .. "/commands.lua")

minetest.log("action", "[rms_menotics] RMS Menotics Cruise Ship Mod loaded successfully!")
