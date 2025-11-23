local fw = require("tests.fw")


fw.test("math.huge", function()
  fw.pass(math.huge)
end)

fw.test("-math.huge", function()
  fw.pass(-math.huge)
end)

fw.test("nan", function()
  fw.pass(0/0)
end)
