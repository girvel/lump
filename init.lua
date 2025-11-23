--- @diagnostic disable:inject-field

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

--- @param data string
--- @param i integer
--- @return number, integer
local read_double = function(data, i)
  local b6 = data:byte(i + 6)
  local b7 = data:byte(i + 7)
  local mantissa = data:byte(i)
    + data:byte(i + 1) * 2^8
    + data:byte(i + 2) * 2^16
    + data:byte(i + 3) * 2^24
    + data:byte(i + 4) * 2^32
    + data:byte(i + 5) * 2^40
    + (b6 % 2^4) * 2^48

  local exponent = (math.floor(b6 / 2^4) + (b7 % 2^7) * 2^4) - 1023
  local sign = b7 >= 128 and -1 or 1
  return sign * (1 + mantissa / 2^52) * 2^exponent, i + 8
end

local NIL = 0x00
local FALSE = 0x01
local TRUE = 0x02
local ZERO = 0x03
local ONE = 0x04
local NUMBER = 0x12
local STRING = 0x20
local TABLE = 0x22

--- @type table<integer, fun(result: number[], x: any)>
local serializers = {}

serializers["nil"] = function(result, x)
  table.insert(result, NIL)
end

serializers.boolean = function(result, x)
  table.insert(result, x and TRUE or FALSE)
end

serializers.number = function(result, x)
  if x == 0 then
    table.insert(result, ZERO)
    return
  elseif x == 1 then
    table.insert(result, ONE)
    return
  end

  table.insert(result, NUMBER)
  write_double(result, x)
end

--- @param result number[]
--- @param x string
serializers.string = function(result, x)
  table.insert(result, STRING)
  write_double(result, #x)
  for char in x:gmatch(".") do
    table.insert(result, string.byte(char))
  end
end

--- @type table<integer, fun(data: string, i: integer): any, integer>
local deserializers = {}

deserializers[NIL] = function(_, i) return nil, i end
deserializers[ZERO] = function(_, i) return 0, i end
deserializers[ONE] = function(_, i) return 1, i end
deserializers[TRUE] = function(_, i) return true, i end
deserializers[FALSE] = function(_, i) return false, i end

deserializers[NUMBER] = function(data, i)
  return read_double(data, i)
end

lump_mt.__call = function(_, value)
  local result = {string.byte("LUMP", 1, 4)}
  serializers[type(value)](result, value)

  local str = ""
  for _, e in ipairs(result) do
    str = str .. string.char(e)
  end
  return str
end

--- @param data string
lump.deserialize = function(data)
  local magic = data:sub(1, 4)
  if magic ~= "LUMP" then
    error(('Expected data to start with "LUMP", got %q instead'):format(magic))
  end

  local type_id = data:byte(5)  -- TODO check
  local result, end_i = deserializers[type_id](data, 6)
  assert(end_i == #data + 1)
  return result
end

return lump
