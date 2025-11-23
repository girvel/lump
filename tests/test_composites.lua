local fw = require("tests.fw")

fw.test("pass: multiple table references", function()
  local ref = {value = 1}
  local t = {a = ref, b = ref}

  local copy = fw.pass(t)
  fw.assert_same(t, copy)
  assert(copy.a == copy.b)
end)

fw.test("pass: multiple function references", function()
  local ref = function() return 123 end
  local t = {a = ref, b = ref}

  local copy = fw.pass(t)
  fw.assert_same(t, copy)
  assert(copy.a == copy.b)
end)

-- TODO multiple string references
-- TODO "size" string
-- TODO i8
