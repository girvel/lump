local lump = require("init")
local fw = require("tests.fw")

fw.test("serialization: number", function()
  assert(fw.to_hex(lump(1.0))  == "4C 55 4D 50 12 00 00 00 00 00 00 F0 3F")
  assert(fw.to_hex(lump(-2.0)) == "4C 55 4D 50 12 00 00 00 00 00 00 00 C0")
end)

fw.test("serialization: string", function()
  assert(fw.to_hex(lump("Hello, world!")) == "4C 55 4D 50 20 00 00 00 00 00 00 2A 40 48 65 6C 6C 6F 2C 20 77 6F 72 6C 64 21")
end)

fw.test("pass: number", function()
  assert(lump.deserialize(lump(123)) == 123)
end)
