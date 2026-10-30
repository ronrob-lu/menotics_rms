local function to_str(x) return x .. "" end

local old_pos = {x=1, y=2, z=3.3}
local new_pos = {x=1, y=2, z=4.4}
print("old_pos", old_pos.x, old_pos.y, old_pos.z)
print("new_pos", new_pos.x, new_pos.y, new_pos.z)

local old_pos_quant = {
    x = math.floor(old_pos.x + 0.5),
    y = math.floor(old_pos.y + 0.5),
    z = math.floor(old_pos.z + 0.5)
}
local new_pos_quant = {
    x = math.floor(new_pos.x + 0.5),
    y = math.floor(new_pos.y + 0.5),
    z = math.floor(new_pos.z + 0.5)
}

print("old_pos_quant", old_pos_quant.x, old_pos_quant.y, old_pos_quant.z)
print("new_pos_quant", new_pos_quant.x, new_pos_quant.y, new_pos_quant.z)

local diff = {
    x = new_pos_quant.x - old_pos_quant.x,
    y = new_pos_quant.y - old_pos_quant.y,
    z = new_pos_quant.z - old_pos_quant.z
}
print("diff quant", diff.x, diff.y, diff.z)

local diff2 = {
    x = new_pos.x - old_pos.x,
    y = new_pos.y - old_pos.y,
    z = new_pos.z - old_pos.z
}
print("diff float", diff2.x, diff2.y, diff2.z)
