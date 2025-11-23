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
  if type(x) == "function" then
    local x_result = x()
    local expected_result = expected()

    fw.assert_same(expected_result, x_result)
    return
  end

  if type(x) == "table" then
    for k, v in pairs(expected) do
      assert(type(k) ~= "table")
      fw.assert_same(x[k], v)
    end
    return
  end

  if x ~= expected then
    error(("Expected %s, got %s"):format(expected, x))
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
fw.assert_pass = function(x)
  local lump = require("init")
  fw.assert_same(lump.deserialize(lump(x)), x)
end

local failed

--- @param name string
--- @param test fun()
fw.test = function(name, test)
  io.stdout:write(name .. " ")
  local ok, msg = xpcall(test, debug.traceback)
  if ok then
    print("+")
  else
    failed = true
    print(("-\n  %s"):format(msg))
  end
end

--- @param tests string[]
fw.run = function(tests)
  failed = false
  for i, test in ipairs(tests) do
    print(("%s\n%s"):format(test, ("-"):rep(#test)))
    dofile(test)
    if i < #tests then
      print()
    end
  end

  os.exit(failed and 1 or 0)
end

return fw
