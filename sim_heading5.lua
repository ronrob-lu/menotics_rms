function local_to_world(off, heading)
    heading = heading % 4
    if heading == 0 then return {x=off.x, y=off.y, z=off.z}
    elseif heading == 1 then return {x=-off.z, y=off.y, z=off.x}
    elseif heading == 2 then return {x=-off.x, y=off.y, z=-off.z}
    elseif heading == 3 then return {x=off.z, y=off.y, z=-off.x}
    end
end
function world_to_local(off, heading)
    heading = heading % 4
    if heading == 0 then return {x=off.x, y=off.y, z=off.z}
    elseif heading == 1 then return {x=-off.z, y=off.y, z=off.x} -- wait, this is local_to_world again!
    -- let's check what ship_nodes.lua does for world_to_local
    end
end
