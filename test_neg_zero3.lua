local function test_keys(move_vec)
    local old_pos = {x=0, y=0, z=0}
    local new_pos = {x=move_vec.x, y=move_vec.y, z=move_vec.z}

    old_pos = {
        x = math.floor(old_pos.x + 0.5),
        y = math.floor(old_pos.y + 0.5),
        z = math.floor(old_pos.z + 0.5)
    }
    new_pos = {
        x = math.floor(new_pos.x + 0.5),
        y = math.floor(new_pos.y + 0.5),
        z = math.floor(new_pos.z + 0.5)
    }

    local active_nodes = {}
    active_nodes["0,0,0"] = {lx=0, ly=0, lz=0}
    active_nodes["0,0,1"] = {lx=0, ly=0, lz=1}

    for key, nd in pairs(active_nodes) do
        -- For an offset in heading 0
        local old_wpos = {
            x = old_pos.x,
            y = old_pos.y,
            z = old_pos.z + nd.lz
        }

        -- The delta check is supposed to be against the NEW position.
        -- But notice in the code, `new_pos` was NOT QUANTIZED inside the loop when doing `rel = vector.subtract(...)` if we refer to the original file. Wait, in original file new_pos WAS quantized on lines 305-306.
        local rel = {
            x = old_wpos.x - new_pos.x,
            y = old_wpos.y - new_pos.y,
            z = old_wpos.z - new_pos.z
        }

        -- Lua -0 formatting check
        local check_key = rel.x .. "," .. rel.y .. "," .. rel.z
        print(string.format("nd=(%d,%d,%d), rel=(%g,%g,%g), check_key=%s", nd.lx, nd.ly, nd.lz, rel.x, rel.y, rel.z, check_key))
    end
end

test_keys({x=1.1, y=0, z=0})
test_keys({x=0, y=0, z=0})
test_keys({x=0, y=0, z=0})
