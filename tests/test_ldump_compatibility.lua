local fw = require("tests.fw")
local lump = require("init")


fw.test("ensure lump(x) is loadable", function()
  local value = {a = 1, b = 2, hello = "world"}
  local dump = lump(value)
  fw.assert_same(value, load(dump)())
end)

-- TODO just straight translation of lump's tests
