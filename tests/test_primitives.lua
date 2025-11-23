local lump = require("init")
local fw = require("tests.fw")

local MAGIC = "4C 55 4D 50 "

-- fw.test("serialization: number", function()
--   assert(fw.to_hex(lump(3.0))  == MAGIC .. "12 00 00 00 00 00 00 08 40")
--   assert(fw.to_hex(lump(-2.0)) == MAGIC .. "12 00 00 00 00 00 00 00 C0")
-- end)

fw.test("serialization: zero/one", function()
  assert(fw.to_hex(lump(0)) == MAGIC .. "03")
  assert(fw.to_hex(lump(1)) == MAGIC .. "04")
end)

fw.test("serialization: string", function()
  assert(fw.to_hex(lump("Hello, world!")) == MAGIC .. "20 0D 48 65 6C 6C 6F 2C 20 77 6F 72 6C 64 21")
end)

fw.test("pass: zero/one", function()
  fw.pass(1)
  fw.pass(0)
end)

fw.test("pass: varint", function()
  fw.pass(123)
end)

fw.test("pass: double", function()
  fw.pass(12.3)
end)

fw.test("pass: nil", function() fw.pass(nil) end)

fw.test("pass: boolean", function()
  fw.pass(true)
  fw.pass(false)
end)

fw.test("pass: string", function()
  fw.pass("Hello, world!")
end)

fw.test("pass: empty string", function()
  fw.pass("")
end)

fw.test("pass: table", function()
  fw.pass({a = 1})
  fw.pass({"Hello, world!"})
end)
