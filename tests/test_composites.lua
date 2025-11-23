local fw = require("tests.fw")
local lump = require("init")

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

fw.test("pass: multiple string references", function()
  local SIZE = 1024
  local str = ""
  for _ = 1, SIZE do
    str = str .. "A"
  end

  local t = {a = str, b = str}
  local dump = lump.serialize(t)

  assert(#dump < SIZE * 2)
  local copy = lump.deserialize(dump)
  fw.assert_same(t, copy)
end)

fw.test("check collision with cache.size", function()
  fw.pass({a = "size", b = "size"})
end)

-- TODO i8
