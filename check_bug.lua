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
    local k = pos.x..","..pos.y..","..pos.z
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
-- Add a 2-block long ship
active_nodes["0,0,0"] = {lx=0, ly=0, lz=0, name="hull"}
active_nodes["0,0,1"] = {lx=0, ly=0, lz=1, name="hull"}

local displaced_water = {}

-- Let's trace move_ship_in_world exactly as written
local function trace_move(old_pos, new_pos)
	old_pos = vector.new(math.floor(old_pos.x + 0.5), math.floor(old_pos.y + 0.5), math.floor(old_pos.z + 0.5))
	new_pos = vector.new(math.floor(new_pos.x + 0.5), math.floor(new_pos.y + 0.5), math.floor(new_pos.z + 0.5))

	print("quant old:", old_pos.x, old_pos.y, old_pos.z)
	print("quant new:", new_pos.x, new_pos.y, new_pos.z)

    for key, nd in pairs(active_nodes) do
		-- Record/Place new
		local new_off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, 0)
		local new_wpos = vector.add(new_pos, new_off)
		local new_wkey = new_wpos.x .. "," .. new_wpos.y .. "," .. new_wpos.z

        print("  Place node " .. new_wkey)

		-- Clear old trailing edge
		local old_off = ship_nodes.local_to_world_offset(nd.lx, nd.ly, nd.lz, 0)
		local old_wpos = vector.add(old_pos, old_off)
		local old_wkey = old_wpos.x .. "," .. old_wpos.y .. "," .. old_wpos.z

		local is_in_new = false
		local rel = vector.subtract(old_wpos, new_pos)
		local check_local = ship_nodes.world_offset_to_local(rel, 0)
		local check_key = check_local.x .. "," .. check_local.y .. "," .. check_local.z

        print("  Checking if old " .. old_wkey .. " is in new. check_key: " .. check_key)

		if active_nodes[check_key] then is_in_new = true end

		if not is_in_new then
            print("  -> Deleting " .. old_wkey)
		end
	end
end

trace_move(vector.new(0,0,1.1), vector.new(0,0,2.2))

print("---")
trace_move(vector.new(0,0,0), vector.new(0,0,1.1))
trace_move(vector.new(0,0,1.1), vector.new(0,0,2.2))
trace_move(vector.new(0,0,2.2), vector.new(0,0,3.3))
print("--- case diff == 0")
trace_move(vector.new(0,0,1.1), vector.new(0,0,1.4))
