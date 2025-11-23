local fw = require("tests.fw")


fw.test("pass: math.huge", function()
  fw.pass(math.huge)
end)

fw.test("pass: -math.huge", function()
  fw.pass(-math.huge)
end)

fw.test("pass: nan", function()
  fw.pass(0/0)
end)
