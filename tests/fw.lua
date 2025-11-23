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

--- @param name string
--- @param test fun()
fw.test = function(name, test)
  io.stdout:write(name .. " ")
  local ok, msg = pcall(test)
  if ok then
    print("+")
  else
    print(("-\n---\n%s\n---"):format(msg))
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
