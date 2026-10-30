local x = 0
local nx = -x
local key1 = x .. "," .. x
local key2 = nx .. "," .. nx
print("key1: " .. key1)
print("key2: " .. key2)
local t = {}
t[key1] = true
print("t[key1]: " .. tostring(t[key1]))
print("t[key2]: " .. tostring(t[key2]))
