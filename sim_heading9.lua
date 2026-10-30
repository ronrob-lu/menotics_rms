local function get_l2w(heading)
    local lx, ly, lz = 1, 2, 3
    heading = heading % 4
    if heading == 0 then return {x=lx, y=ly, z=lz}
    elseif heading == 1 then return {x=lz, y=ly, z=-lx}
    elseif heading == 2 then return {x=-lx, y=ly, z=-lz}
    elseif heading == 3 then return {x=-lz, y=ly, z=lx}
    end
end
local function wtol(off, heading)
	heading = heading % 4
	if heading == 0 then     -- North
		return {x=off.x, y=off.y, z=off.z}
	elseif heading == 1 then -- East
		return {x=-off.z, y=off.y, z=off.x}
	elseif heading == 2 then -- South
		return {x=-off.x, y=off.y, z=-off.z}
	elseif heading == 3 then -- West
		return {x=off.z, y=off.y, z=-off.x}
	end
end

for h=0,3 do
    local w = get_l2w(h)
    local l = wtol(w, h)
    print("Heading", h, "orig: 1,2,3 -> world:", w.x, w.y, w.z, "-> local:", l.x, l.y, l.z)
end
