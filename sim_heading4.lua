vector = {}
function vector.new(x,y,z) return {x=x, y=y, z=z} end
function vector.add(a,b) return {x=a.x+b.x, y=a.y+b.y, z=a.z+b.z} end
function vector.subtract(a,b) return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z} end
function vector.multiply(a,s) return {x=a.x*s, y=a.y*s, z=a.z*s} end

minetest = {}
minetest.registered_nodes = {}
world = {}
function minetest.get_modpath(mod) return "." end
function minetest.get_node_or_nil(pos)
    -- format floating point cleanly for table keys
    local k = string.format("%.0f,%.0f,%.0f", pos.x, pos.y, pos.z)
    if k:find("-0") then k = k:gsub("-0", "0") end -- primitive fix for printing -0
    k = pos.x..","..pos.y..","..pos.z -- reverting to standard logic
    return world[k] or {name="air"}
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

package.loaded.compat = { is_water = function(n) return n == "default:water_source" end }
compat = package.loaded.compat

local ship_nodes = dofile("ship_nodes.lua")

local active_nodes = {}
active_nodes["0,0,0"] = {lx=0, ly=0, lz=0, name="hull"}
active_nodes["0,0,1"] = {lx=0, ly=0, lz=1, name="hull"}

local displaced_water = {}

local function to_str(n)
    if n == 0 and tostring(n) == "-0" then return "-0" end
    return tostring(n)
end

-- Re-implement move_ship_in_world just to print
local function trace_move(old_pos, new_pos, heading)
    old_pos = vector.new(math.floor(old_pos.x + 0.5), math.floor(old_pos.y + 0.5), math.floor(old_pos.z + 0.5))
    new_pos = vector.new(math.floor(new_pos.x + 0.5), math.floor(new_pos.y + 0.5), math.floor(new_pos.z + 0.5))

    for key, nd in pairs(active_nodes) do
        -- Place new
        local new_off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, heading)
        local new_wpos = vector.add(new_pos, new_off)

        -- Clear old
        local old_off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, heading)
        local old_wpos = vector.add(old_pos, old_off)

        local rel = vector.subtract(old_wpos, new_pos)
        local check_local = ship_nodes.world_offset_to_local(rel, heading)
        local check_key = to_str(check_local.x) .. "," .. to_str(check_local.y) .. "," .. to_str(check_local.z)

        print(string.format("Node lx=%d,lz=%d -> old_wpos=(%d,%d,%d) new_wpos=(%d,%d,%d) rel=(%d,%d,%d) check_key=%s",
            nd.lx, nd.lz,
            old_wpos.x, old_wpos.y, old_wpos.z,
            new_wpos.x, new_wpos.y, new_wpos.z,
            rel.x, rel.y, rel.z, check_key))

        if not active_nodes[check_key] then
            print("  -> Will delete " .. old_wpos.x .. "," .. old_wpos.y .. "," .. old_wpos.z)
        end
    end
end

print("Heading 0")
trace_move(vector.new(0,0,1.1), vector.new(0,0,2.2), 0)

print("\nHeading 1")
trace_move(vector.new(1.1,0,0), vector.new(2.2,0,0), 1)

print("\nHeading 2")
trace_move(vector.new(0,0,-1.1), vector.new(0,0,-2.2), 2)

print("\nHeading 3")
trace_move(vector.new(-1.1,0,0), vector.new(-2.2,0,0), 3)
