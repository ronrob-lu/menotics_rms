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

-- If local is (lx=1, ly=2, lz=3) and heading is 1 (East)
-- world = {x=-3, y=2, z=1}
-- wtol = {x=-(1), y=2, z=-3} = {x=-1, y=2, z=-3} -> Wait!
local w = {x=-3, y=2, z=1}
local l = wtol(w, 1)
print(l.x, l.y, l.z)

-- Let's see what the inverse of heading 1 actually is.
-- w.x = -l.z  => l.z = -w.x
-- w.y = l.y   => l.y = w.y
-- w.z = l.x   => l.x = w.z
-- So world_offset_to_local for heading 1 should be:
-- {x = w.z, y = w.y, z = -w.x}
-- But the code has {x = -w.z, y = w.y, z = w.x}
-- WAIT, let's check!

local function true_wtol(off, heading)
    heading = heading % 4
	if heading == 0 then     -- North
		return {x=off.x, y=off.y, z=off.z}
	elseif heading == 1 then -- East
		return {x=off.z, y=off.y, z=-off.x}
	elseif heading == 2 then -- South
		return {x=-off.x, y=off.y, z=-off.z}
	elseif heading == 3 then -- West
		return {x=-off.z, y=off.y, z=off.x}
	end
end
local l_true = true_wtol(w, 1)
print("true", l_true.x, l_true.y, l_true.z)
