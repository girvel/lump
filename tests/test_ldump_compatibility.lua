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

fw.test("lump.serializer.handlers", function()
  local t = {value = 1}
  lump.serializer.handlers[t] = "1"
  fw.assert_equal(1, fw.pass(t))
  lump.serializer.handlers[t] = nil
end)

fw.test("lump.serializer.handlers: threads", function()
  local thread = coroutine.create(function()
    coroutine.yield()
    return 1
  end)
  lump.serializer.handlers[thread] = "404"
  fw.assert_equal(404, fw.pass(thread))
  lump.serializer.handlers[thread] = nil
end)

fw.test("lump.serializer.handlers: caching (function)", function()
  local f = coroutine.wrap(function() end)
  local to_serialize = {a = f, b = f}
  lump.serializer.handlers[f] = function() return {} end

  local copy = fw.pass(to_serialize)
  fw.assert_equal(copy.a, copy.b)

  lump.serializer.handlers[f] = nil
end)

fw.test("lump.serializer.handlers: caching (string)", function()
  local f = coroutine.wrap(function() end)
  local to_serialize = {a = f, b = f}
  lump.serializer.handlers[f] = [[{}]]

  local copy = fw.pass(to_serialize)
  fw.assert_equal(copy.a, copy.b)

  lump.serializer.handlers[f] = nil
end)

fw.test("__serialize", function()
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
