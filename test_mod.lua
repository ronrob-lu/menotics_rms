-- Unit & Integration Tests for RMS Menotics Mod

-- Mock Minetest Engine Globals
minetest = {}
minetest.registered_nodes = {}
minetest.registered_crafts = {}
minetest.registered_entities = {}
minetest.registered_chatcommands = {}
minetest.registered_items = {}
minetest.luaentities = {}

vector = {}
function vector.new(x, y, z)
	if type(x) == "table" then return {x = x.x, y = x.y, z = x.z} end
	return {x = x or 0, y = y or 0, z = z or 0}
end
function vector.add(a, b) return {x = a.x + b.x, y = a.y + b.y, z = a.z + b.z} end
function vector.subtract(a, b) return {x = a.x - b.x, y = a.y - b.y, z = a.z - b.z} end
function vector.multiply(a, s) return {x = a.x * s, y = a.y * s, z = a.z * s} end

function minetest.get_modpath(mod)
	if mod == "rms_menotics" then
		return "."
	end
	return nil
end

function minetest.register_node(name, def)
	minetest.registered_nodes[name] = def
end

function minetest.register_craftitem(name, def)
	minetest.registered_items[name] = def
end

function minetest.register_craft(def)
	table.insert(minetest.registered_crafts, def)
end

function minetest.register_entity(name, def)
	if minetest.registered_entities[name] then
		error("Duplicate entity registration for " .. name)
	end
	minetest.registered_entities[name] = def
end

function minetest.register_chatcommand(name, def)
	minetest.registered_chatcommands[name] = def
end

function minetest.register_on_placenode(fn) end
function minetest.register_on_dignode(fn) end

function minetest.serialize(val) return "serialized_data" end
function minetest.deserialize(str) return {} end

function minetest.get_mod_storage()
	return {
		get_string = function() return "" end,
		set_string = function() end,
	}
end

function minetest.log(level, msg) end

-- Mock world nodes
local world_nodes = {}
function minetest.set_node(pos, node)
	local key = pos.x .. "," .. pos.y .. "," .. pos.z
	world_nodes[key] = node
end
function minetest.get_node(pos)
	local key = pos.x .. "," .. pos.y .. "," .. pos.z
	return world_nodes[key] or {name = "air", param1 = 0, param2 = 0}
end
function minetest.get_node_or_nil(pos)
	return minetest.get_node(pos)
end

---------------------------------------------------------
-- RUN TESTS
---------------------------------------------------------

print("=== RUNNING RMS MENOTICS UNIT TESTS ===")

-- 1. Load Mod Modules via init.lua (as Minetest does)
dofile("init.lua")
local ship_nodes = dofile("ship_nodes.lua")
local entity_mod = rms_menotics.entity

print("[TEST 1] Registered Nodes & Recipes")
assert(minetest.registered_nodes["rms_menotics:deck"], "Deck node missing")
assert(minetest.registered_nodes["rms_menotics:railing"], "Railing node missing")
assert(minetest.registered_nodes["rms_menotics:hull"], "Hull node missing")
assert(minetest.registered_nodes["rms_menotics:glass"], "Glass node missing")
assert(minetest.registered_nodes["rms_menotics:chair"], "Chair node missing")
assert(minetest.registered_items["rms_menotics:cruise_ship"], "Cruise ship item missing")
assert(#minetest.registered_crafts > 0, "Crafting recipe missing")
print("  -> PASSED: All nodes and items registered successfully.")

print("[TEST 2] Facedir & Wallmounted Rotation Maps")
assert(ship_nodes.facedir_cw_map[0] == 1, "Facedir 0 -> 1 failed")
assert(ship_nodes.facedir_cw_map[1] == 2, "Facedir 1 -> 2 failed")
assert(ship_nodes.facedir_cw_map[2] == 3, "Facedir 2 -> 3 failed")
assert(ship_nodes.facedir_cw_map[3] == 0, "Facedir 3 -> 0 failed")

assert(ship_nodes.wallmounted_cw_map[2] == 4, "Wallmounted North -> East failed")
assert(ship_nodes.wallmounted_cw_map[4] == 3, "Wallmounted East -> South failed")
assert(ship_nodes.wallmounted_cw_map[3] == 5, "Wallmounted South -> West failed")
assert(ship_nodes.wallmounted_cw_map[5] == 2, "Wallmounted West -> North failed")
print("  -> PASSED: Rotation maps correct.")

print("[TEST 3] Ship Local to World Transformations")
local off_n = ship_nodes.local_to_world_offset(3, 5, 10, 0) -- North
assert(off_n.x == 3 and off_n.y == 5 and off_n.z == 10, "North offset failed")

local off_e = ship_nodes.local_to_world_offset(3, 5, 10, 1) -- East
assert(off_e.x == 10 and off_e.y == 5 and off_e.z == -3, "East offset failed")

local off_s = ship_nodes.local_to_world_offset(3, 5, 10, 2) -- South
assert(off_s.x == -3 and off_s.y == 5 and off_s.z == -10, "South offset failed")

local off_w = ship_nodes.local_to_world_offset(3, 5, 10, 3) -- West
assert(off_w.x == -10 and off_w.y == 5 and off_w.z == 3, "West offset failed")
print("  -> PASSED: Local-to-world offsets verified for all 4 cardinal headings.")

print("[TEST 4] Default Ship Generator & Spatial Hashing")
local t_start = os.clock()
local active_nodes = ship_nodes.generate_default_ship_data()
local t_gen = (os.clock() - t_start) * 1000

local count = 0
for k, v in pairs(active_nodes) do
	count = count + 1
end

print(string.format("  -> Active nodes count: %d (generated in %.2f ms)", count, t_gen))
assert(count > 1000 and count < 15000, "Active node count out of expected bounds")
assert(count < 22500, "Optimization failure: Spatial hash must NOT contain empty air/water nodes!")

print("[TEST 4b] Command Bridge & Ship Initial Movement State")
assert(active_nodes["0,12,32"] and active_nodes["0,12,32"].name == "rms_menotics:hull", "Bridge roof node missing")
assert(active_nodes["0,11,36"] and active_nodes["0,11,36"].name == "rms_menotics:glass", "Bridge forward glass window missing")
assert(active_nodes["0,10,35"] and active_nodes["0,10,35"].name == "rms_menotics:steering_wheel", "Bridge command console steering wheel missing")
assert(active_nodes["1,10,35"] and active_nodes["1,10,35"].name == "rms_menotics:engine_control", "Bridge command console engine control missing")
assert(active_nodes["2,10,35"] and active_nodes["2,10,35"].name == "rms_menotics:railing", "Bridge command console railing missing")

local ship_ent_def = minetest.registered_entities["rms_menotics:ship_entity"]
assert(ship_ent_def, "Ship entity not registered")
assert(ship_ent_def.state == "manual", "Initial entity state should be manual")
assert(ship_ent_def.speed == 0.0, "Initial entity speed should be 0.0")
print("  -> PASSED: Command bridge nodes and manual state verified.")

print("[TEST 5] Depth Scanning & Iceberg Detection")
-- Setup water in world
for z = -60, 60 do
	for y = -6, 0 do
		for x = -20, 20 do
			world_nodes[x .. "," .. y .. "," .. z] = {name = "default:water_source"}
		end
	end
end

local center = vector.new(0, 0, 0)
local depth_ok, err = entity_mod.check_water_depth(center, 0)
assert(depth_ok == true, "Water depth check failed on valid water: " .. tostring(err))

-- Place ice block ahead
world_nodes["0,1,52"] = {name = "default:ice"}
local status, hpos, hname = entity_mod.scan_ahead(center, 0)
assert(status == "iceberg", "Iceberg scanning failed, status was: " .. tostring(status))
assert(hname == "default:ice", "Hazard name mismatch")

-- Verify on_step halts on iceberg rather than calling sinking
local dummy_ship_obj = {
	pos = vector.new(0, 0, 0),
	get_pos = function(self) return self.pos end,
	set_pos = function(self, p) self.pos = p end,
	set_velocity = function(self, v) self.velocity = v end,
}
local test_ship = {
	object = dummy_ship_obj,
	heading = 0,
	speed = 2.2,
	accum_step = 0.5,
	state = "manual",
	active_nodes = {},
	displaced_water = {},
	last_placed_pos = vector.new(0, 0, 0),
}
ship_ent_def.on_step(test_ship, 0.1)
assert(test_ship.speed == 0.0, "Ship should halt on iceberg collision")
assert(test_ship.state == "manual", "Ship state should remain manual and not transition to sinking")
print("  -> PASSED: Iceberg detection & depth scanning operating properly.")

print("[TEST 6] Item OnPlace callback execution without re-registering entities")
minetest.settings = { get_bool = function() return true end }
minetest.add_entity = function(pos, name)
	return { get_luaentity = function() return {} end, set_yaw = function() end }
end
local cruise_ship_item = minetest.registered_items["rms_menotics:cruise_ship"]
assert(cruise_ship_item and cruise_ship_item.on_place, "Cruise ship on_place missing")
local dummy_placer = {
	get_look_horizontal = function() return 0 end,
	is_player = function() return true end,
	get_player_name = function() return "Tester" end,
}
local pointed = {
	type = "node",
	under = {x = 0, y = 0, z = 0},
	above = {x = 0, y = 1, z = 0},
}
-- Call on_place; if it executes dofile("entity.lua") which calls register_entity, error will be thrown
cruise_ship_item.on_place({}, dummy_placer, pointed)
print("  -> PASSED: on_place executed without re-registering entity.")

print("=== ALL UNIT TESTS PASSED SUCCESSFULLY ===")
