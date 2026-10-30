local function local_to_world_offset(lx, ly, lz, heading)
    heading = heading % 4
    if heading == 0 then return {x=lx, y=ly, z=lz}
    elseif heading == 1 then return {x=lz, y=ly, z=-lx}
    elseif heading == 2 then return {x=-lx, y=ly, z=-lz}
    elseif heading == 3 then return {x=-lz, y=ly, z=lx}
    end
end
