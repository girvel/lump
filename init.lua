local lump_mt = {}
local lump = setmetatable({}, lump_mt)

--- @param result number[]
--- @param x number
local write_double = function(result, x)
  local sign = 0
  if x < 0 then
    sign = 1
    x = -x
  end

  local mantissa, exponent = math.frexp(x)
  --- IEEE 754
  exponent = exponent + 1022
  if exponent <= 0 then  -- TODO handle the case when > 1023?
    exponent = 0
    mantissa = 0
  else
    mantissa = mantissa * 2 - 1
  end

  local mantissa_high_bits = math.floor(mantissa * 2^20)
  local mantissa_low_bits = math.floor(mantissa * 2^52 - mantissa_high_bits * 2^32)

  local exponent_high_bits = math.floor(exponent / 2^4)
  local exponent_low_bits = exponent % 2^4

  table.insert(result, mantissa_low_bits % 2^8)
  table.insert(result, math.floor(mantissa_low_bits / 2^8) % 2^8)
  table.insert(result, math.floor(mantissa_low_bits / 2^16) % 2^8)
  table.insert(result, math.floor(mantissa_low_bits / 2^24) % 2^8)

  table.insert(result, mantissa_high_bits % 2^8)
  table.insert(result, math.floor(mantissa_high_bits / 2^8) % 2^8)
  table.insert(result, exponent_low_bits * 2^4 + math.floor(mantissa_high_bits / 2^16))
  table.insert(result, sign * 2^7 + exponent_high_bits)
end

lump_mt.__call = function(_, value)
  assert(type(value) == "number")

  local result = {string.byte("LUMP", 1, 4)}
  table.insert(result, 0x12)
  write_double(result, value)

  local str = ""
  for _, e in ipairs(result) do
    str = str .. string.char(e)
  end
  return str
end

local to_hex = function(str)
  local result, _ = str:gsub(".", function(char)
    return string.format("%02X ", string.byte(char))
  end)
  return result
end

local to_bin = function(str)
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

print(to_bin(lump(1.0)))
print(to_bin(lump(-2.0)))

return lump
