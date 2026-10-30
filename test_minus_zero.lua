local function get_key(lx, ly, lz)
    return lx .. "," .. ly .. "," .. lz
end

local function test_heading(heading)
    local off = {x=0, y=0, z=0}
    local local_pos
    if heading == 0 then local_pos = {x=off.x, y=off.y, z=off.z}
    elseif heading == 1 then local_pos = {x=-off.z, y=off.y, z=off.x}
    elseif heading == 2 then local_pos = {x=-off.x, y=off.y, z=-off.z}
    elseif heading == 3 then local_pos = {x=off.z, y=off.y, z=-off.x}
    end
    print("Heading " .. heading .. " key: " .. get_key(local_pos.x, local_pos.y, local_pos.z))
end

test_heading(0)
test_heading(1)
test_heading(2)
test_heading(3)
