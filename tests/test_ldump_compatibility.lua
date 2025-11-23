local fw = require("tests.fw")
local lump = require("init")


local load = loadstring or load

fw.test("ensure lump(x) is loadable", function()
  local value = {a = 1, b = 2, hello = "world"}
  local dump = lump(value)
  fw.assert_same(value, load(dump)())
end)

fw.test("lump.serializer: string, wrong type", function()
  local old_serializer = lump.serializer
  lump.serializer = function(x)
    if type(x) == "thread" then
      return "404", "serializer's thread handling"
    end

    if type(x) == "function" then
      return 0, "serializer's function handling"
    end
  end

  local thread = coroutine.create(function() end)
  local t = {a = 1, b = 2, c = coroutine.create(function() end)}
  local f = function() end

  fw.assert_equal(404, fw.pass(thread))
  fw.assert_same({a = 1, b = 2, c = 404}, fw.pass(t))

  local ok = pcall(lump.serialize, f)
  fw.assert_equal(ok, false)

  lump.serializer = old_serializer
end)

fw.test("lump.serializer: function", function()
  local old_serializer = lump.serializer
  local v = {}

  lump.serializer = function(x)
    if x == v then
      return function()
        return "HEHE"
      end, "serializer's string handling"
    end
  end

  fw.assert_equal(fw.pass(v), "HEHE")

  lump.serializer = old_serializer
end)

fw.test("metatable's __serialize returning function", function()
  local t = setmetatable({a = 1}, {
    __serialize = function(self)
      local a = self.a
      return function()
        return a
      end
    end
  })

  fw.assert_equal(fw.pass(t), 1)
end)


-- TODO just straight translation of lump's tests
