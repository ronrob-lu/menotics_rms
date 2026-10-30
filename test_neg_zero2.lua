local function test_keys(heading, move_vec)
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
        -- Clear old trailing edge logic:
        local old_off_z = nd.lz -- assuming heading 0
        local old_wpos = {x = old_pos.x, y = old_pos.y, z = old_pos.z + old_off_z}

        local rel = {
            x = old_wpos.x - new_pos.x,
            y = old_wpos.y - new_pos.y,
            z = old_wpos.z - new_pos.z
        }

        local check_local_z = rel.z -- assuming heading 0
        local check_key = rel.x .. "," .. rel.y .. "," .. rel.z

        print(string.format("old_wpos=(%d,%d,%d), new_pos=(%d,%d,%d), rel=(%g,%g,%g), check_key=%s",
            old_wpos.x, old_wpos.y, old_wpos.z,
            new_pos.x, new_pos.y, new_pos.z,
            rel.x, rel.y, rel.z, check_key))

        if active_nodes[check_key] then
            print("  FOUND in new pos")
        else
            print("  NOT FOUND - deleting old node")
        end
    end
end

print("Testing +z move")
test_keys(0, {x=0, y=0, z=1.1})

print("Testing with precision issues")
test_keys(0, {x=0, y=0, z=2.2})
