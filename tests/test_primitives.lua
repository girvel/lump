local lump = require("init")
local fw = require("tests.fw")

local MAGIC = "4C 55 4D 50 "

fw.test("serialization: number", function()
  assert(fw.to_hex(lump(3.0))  == MAGIC .. "12 00 00 00 00 00 00 08 40")
  assert(fw.to_hex(lump(-2.0)) == MAGIC .. "12 00 00 00 00 00 00 00 C0")
end)

fw.test("serialization: zero/one", function()
  assert(fw.to_hex(lump(0)) == MAGIC .. "03")
  assert(fw.to_hex(lump(1)) == MAGIC .. "04")
end)

fw.test("serialization: string", function()
  assert(fw.to_hex(lump("Hello, world!")) == "4C 55 4D 50 20 00 00 00 00 00 00 2A 40 48 65 6C 6C 6F 2C 20 77 6F 72 6C 64 21")
end)

local pass = function(x)
  assert(lump.deserialize(lump(x)) == x)
end

fw.test("pass: number", function()
  pass(123)
end)

fw.test("pass: zero/one", function()
  pass(1)
  pass(0)
end)
