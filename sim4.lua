print(tostring(-0))
local a = -0
local key = a .. ",0,0"
print(key)
local t = {}
t["0,0,0"] = "found"
print(t[key] or "not found")
