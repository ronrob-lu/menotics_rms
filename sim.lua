vector = {}
function vector.new(x,y,z) return {x=x, y=y, z=z} end
function vector.add(a,b) return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z} end
function vector.subtract(a,b) return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z} end
function vector.multiply(a,s) return {x=a.x*s, y=a.y*s, z=a.z*s} end

minetest = {}
local world = {}
function minetest.get_node_or_nil(pos)
    local k = pos.x..","..pos.y..","..pos.z
    return world[k]
end
function minetest.get_node(pos)
    local k = pos.x..","..pos.y..","..pos.z
    return world[k] or {name="air"}
end
function minetest.set_node(pos, node)
    local k = pos.x..","..pos.y..","..pos.z
    if node.name == "air" then
        world[k] = nil
    else
        world[k] = node
    end
end
function minetest.get_meta(pos) return nil end
compat = { is_water = function(n) return n == "default:water_source" end }

local ship_nodes = dofile("ship_nodes.lua")

local active_nodes = {}
-- Make a small 3-block long ship
active_nodes["0,0,0"] = {lx=0, ly=0, lz=0, name="hull"}
active_nodes["0,0,1"] = {lx=0, ly=0, lz=1, name="hull"}
active_nodes["0,0,2"] = {lx=0, ly=0, lz=2, name="hull"}

local displaced_water = {}

-- Place ship at 0
ship_nodes.place_ship_in_world(vector.new(0,0,0), 0, active_nodes, displaced_water)

local last_placed_pos = vector.new(0,0,0)
local move_vec = vector.new(0,0,1.1)

for tick=1, 10 do
    local base_pos = last_placed_pos
    local new_pos = vector.add(base_pos, move_vec)
    displaced_water = ship_nodes.move_ship_in_world(base_pos, new_pos, 0, active_nodes, displaced_water)
    last_placed_pos = new_pos

    local c = 0
    for k,v in pairs(world) do c = c + 1 end
    print("Tick " .. tick .. " - Blocks in world: " .. c .. " - expected 3")
end
