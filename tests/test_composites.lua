local fw = require("tests.fw")

fw.test("pass: multiple references", function()
  local ref = {value = 1}
  local t = {a = ref, b = ref}

  local copy = fw.pass(t)
  fw.assert_same(t, copy)
  assert(copy.a == copy.b)
end)

-- TODO multiple function references
