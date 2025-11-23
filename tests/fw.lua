local fw = {}

--- @param str string
--- @return string
fw.to_hex = function(str)
  local result, _ = str:gsub(".", function(char)
    return string.format("%02X ", string.byte(char))
  end)
  return result:sub(1, -2)
end

--- @param str string
--- @return string
fw.to_bin = function(str)
  local result, _ = str:gsub(".", function(x)
    x = string.byte(x)
    local s = ""
    for _ = 1, 8 do
      s = (x % 2) .. s
      x = math.floor(x / 2)
    end
    return s .. " "
  end)
  return result
end

fw.assert_same = function(x, expected)
  if type(x) ~= "table" then
    assert(x == expected)
    return
  end

  for k, v in pairs(expected) do
    assert(type(k) ~= "table")
    fw.assert_same(x[k], v)
  end
end

--- @generic T
--- @param x T
--- @return T
fw.pass = function(x)
  local lump = require("init")
  return lump.deserialize(lump(x))
end

--- @param x any
fw.assert_pass = function(x, ...)
  local lump = require("init")
  local dump = lump(x)
  local copy = lump.deserialize(dump)
  if type(x) == "table" then
    fw.assert_same(copy, x)
  elseif type(x) == "function" then
    fw.assert_same(copy(...), x(...))
  else
    if copy ~= x then
      error(("Expected %s to stay the same, got %s instead\n%s"):format(x, copy, fw.to_hex(dump)))
    end
  end
end

--- @param name string
--- @param test fun()
fw.test = function(name, test)
  io.stdout:write(name .. " ")
  local ok, msg = xpcall(test, debug.traceback)
  if ok then
    print("+")
  else
    print(("-\n  %s"):format(msg))
  end
end

--- @param tests string[]
fw.run = function(tests)
  for i, test in ipairs(tests) do
    local name = test
    print(("%s\n%s"):format(name, ("-"):rep(#name)))
    dofile(test)
    if i > 1 then
      print()
    end
  end
end

return fw
