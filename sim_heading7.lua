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
