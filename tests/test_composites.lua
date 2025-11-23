local fw = require("tests.fw")
local lump = require("init")

fw.test("pass: table", function()
  fw.assert_pass({a = 1})
  fw.assert_pass({"Hello, world!"})
end)

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

-- TODO function circular references?
-- TODO function references to itself
fw.test("pass: table circular references", function()
  local t = {a = {}, b = {}}
  t.a.b = t.b
  t.b.a = t.a
  local result = fw.pass(t)
  fw.assert_same(t, result)
  fw.assert_equal(result.a.b, result.b)
  fw.assert_equal(result.b.a, result.a)
end)

fw.test("pass: table references to itself", function()
  local t = {}
  t.t = t
  local result = fw.pass(t)
  fw.assert_same(t, result)
  fw.assert_equal(result, result.t)
end)

fw.test("tables as keys", function()
  local t = {}
  t[t] = t
  local result = fw.pass(t)
  fw.assert_equal(result[result], result)
end)

fw.test("table with metatable", function()
  local t = setmetatable({value = 1}, {__call = function(self) return self.value end})
  fw.assert_equal(1, fw.pass(t)())
end)

fw.test("function with upvalues (closure)", function()
  local a = 1
  local b = 2
  local f = function() return a + b end
  fw.assert_pass(f)
end)

-- TODO benchmarking facility
