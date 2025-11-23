local lump = require("init")
local fw = require("tests.fw")


-- TODO another way: __bin_serialize, __bin_deserialize

-- fw.test("metatable's __serialize returning function", function()
--   local t = setmetatable({a = 1}, {
--     __serialize = function(self)
--       local a = self.a
--       return function()
--         return a
--       end
--     end
--   })
-- 
--   fw.assert_equal(fw.pass(t), 1)
-- end)

fw.test("custom serializer", function()
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

