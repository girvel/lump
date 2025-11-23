--- @diagnostic disable:inject-field

local lump_modpath = ...

local load = loadstring or load
local unpack = unpack or table.unpack

local lump_mt = {}
--- @overload fun(x: any): string
local lump = setmetatable({}, lump_mt)

--- @param result integer[]
--- @param x integer
--- @param i? integer
local write_varint = function(result, x, i)
  i = i or #result + 1  -- TODO maybe remove i arguments?
  while true do
    local item = x % 128
    x = math.floor(x / 128)
    if x == 0 then
      result[i] = item
      break
    else
      result[i] = 128 + item
      i = i + 1
    end
  end
end

--- @param data string
--- @param i integer
--- @return integer, integer
local read_varint = function(data, i)
  local result = 0
  local multiplier = 1
  while true do
    local byte = data:byte(i)
    i = i + 1

    if byte < 128 then
      result = result + byte * multiplier
      break
    else
      result = result + (byte - 128) * multiplier
      multiplier = multiplier * 128
    end
  end
  return result, i
end

--- @param result integer[]
--- @param x number
--- @param i? integer
local write_double = function(result, x, i)
  i = i or #result + 1

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

  result[i] = mantissa_low_bits % 2^8
  result[i + 1] = math.floor(mantissa_low_bits / 2^8) % 2^8
  result[i + 2] = math.floor(mantissa_low_bits / 2^16) % 2^8
  result[i + 3] = math.floor(mantissa_low_bits / 2^24) % 2^8

  result[i + 4] = mantissa_high_bits % 2^8
  result[i + 5] = math.floor(mantissa_high_bits / 2^8) % 2^8
  result[i + 6] = exponent_low_bits * 2^4 + math.floor(mantissa_high_bits / 2^16)
  result[i + 7] = sign * 2^7 + exponent_high_bits
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

--- @param result integer[]
--- @param x string
local write_string = function(result, x)
  local len = #x
  write_varint(result, len)
  for i = 1, len do
    table.insert(result, x:byte(i))
  end
end

--- @param data string
--- @param i integer
--- @return string, integer
local read_string = function(data, i)
  local size
  size, i = read_varint(data, i)

  local result = data:sub(i, i + size - 1)
  i = i + size

  return result, i
end

-- TODO luajit has -0
-- TODO reassign when ready
local NIL = 0x00
local FALSE = 0x01
local TRUE = 0x02
local ZERO = 0x03
local ONE = 0x04
local INFINITY = 0x05
local NEGATIVE_INFINITY = 0x06
local NAN = 0x07
local VARINT = 0x10
local VARINT_NEGATIVE = 0x11
local NUMBER = 0x12
local STRING = 0x20
local BIG_STRING = 0x21
local TABLE = 0x22
local TABLE_WITH_METATABLE = 0x23
local FUNCTION = 0x24
local REF = 0x25
local CODE = 0x26

-- NOTICE must be bigger than 4, or it would collide with cache.size
local BIG_STRING_THRESHOLD = 32

--- @class serialization_cache: table<any, integer>
--- @field size integer

--- @type table<string, fun(result: number[], cache: serialization_cache, x: any)>
local serializers = {}

local serialize

--- @param result number[]
--- @param cache serialization_cache
--- @param x any
serialize = function(result, cache, x)
  local cached_as = cache[x]
  if cached_as then
    table.insert(result, REF)
    write_varint(result, cached_as)
    return
  end

  do  -- handle override
    local override = lump.serializer(x)
    if override then
      local override_type, source = type(override)

      if override_type == "string" then
        table.insert(result, CODE)
        -- TODO caching
        write_string(result, override)
        return
      end

      -- TODO serialization stack
      error(string.format(
        "%s returned type %s; it should return string or function",
        source or "lump.serializer", override_type
      ))
    end
  end

  local x_type = type(x)
  local serializer = serializers[x_type]
  if not serializer then
    error(("Impossible to serialize %s"):format(x_type))
  end
  serializer(result, cache, x)
end

serializers["nil"] = function(result, cache, x)
  table.insert(result, NIL)
end

serializers.boolean = function(result, cache, x)
  table.insert(result, x and TRUE or FALSE)
end

serializers.number = function(result, cache, x)
  if x == 0 then
    table.insert(result, ZERO)
    return
  elseif x == 1 then
    table.insert(result, ONE)
    return
  elseif x == math.huge then
    table.insert(result, INFINITY)
    return
  elseif x == -math.huge then
    table.insert(result, NEGATIVE_INFINITY)
    return
  elseif x ~= x then
    table.insert(result, NAN)
    return
  elseif x % 1 == 0 then
    if x > 0 then
      table.insert(result, VARINT)
      write_varint(result, x)
    else
      table.insert(result, VARINT_NEGATIVE)
      write_varint(result, -x)
    end
    return
  end

  table.insert(result, NUMBER)
  write_double(result, x)
end

serializers.string = function(result, cache, x)
  if #x < BIG_STRING_THRESHOLD then
    table.insert(result, STRING)
  else
    table.insert(result, BIG_STRING)
    cache.size = cache.size + 1
    cache[x] = cache.size
    write_varint(result, cache.size)
  end

  write_string(result, x)
end

serializers.table = function(result, cache, x)
  local mt = getmetatable(x)

  table.insert(result, mt and TABLE_WITH_METATABLE or TABLE)
  cache.size = cache.size + 1
  cache[x] = cache.size
  write_varint(result, cache.size)

  local size = 0
  for _ in pairs(x) do
    size = size + 1
  end
  write_varint(result, size)

  for k, v in pairs(x) do
    serialize(result, cache, k)
    serialize(result, cache, v)
  end

  if mt then
    serialize(result, cache, mt)
  end
end

serializers["function"] = function(result, cache, x)
  table.insert(result, FUNCTION)

  cache.size = cache.size + 1
  cache[x] = cache.size
  write_varint(result, cache.size)

  write_string(result, string.dump(x))

  local upvalues_n = 0
  while debug.getupvalue(x, upvalues_n + 1) do
    upvalues_n = upvalues_n + 1
  end

  write_varint(result, upvalues_n)

  for i = 1, upvalues_n do
    local _, v = debug.getupvalue(x, i)

    local id
    if debug.upvalueid then
      local userdata_id = debug.upvalueid(x, i)
      id = cache[userdata_id]
      if not id then
        cache.size = cache.size + 1
        cache[userdata_id] = cache.size
        id = cache.size
      end
    else
      id = 0
    end
    write_varint(result, id)

    serialize(result, cache, v)
    -- TODO handle _ENV
    -- TODO handle joined upvalues
  end
end

--- @alias deserialization_cache table<integer, any>

--- @type table<integer, fun(data: string, cache: deserialization_cache, i: integer): any, integer>
local deserializers = {}

--- @param data string
--- @param cache deserialization_cache
--- @param i integer
--- @return any, integer
local deserialize = function(data, cache, i)
  local type_id = data:byte(i)
  local deserializer = deserializers[type_id]
  if not deserializer then
    error(("Unknown type ID 0x%02X"):format(type_id))
  end

  return deserializer(data, cache, i + 1)
end

deserializers[NIL] = function(_, _, i) return nil, i end
deserializers[TRUE] = function(_, _, i) return true, i end
deserializers[FALSE] = function(_, _, i) return false, i end
deserializers[ZERO] = function(_, _, i) return 0, i end
deserializers[ONE] = function(_, _, i) return 1, i end
deserializers[INFINITY] = function(_, _, i) return math.huge, i end
deserializers[NEGATIVE_INFINITY] = function(_, _, i) return -math.huge, i end
deserializers[NAN] = function(_, _, i) return 0/0, i end

deserializers[NUMBER] = function(data, _, i)
  return read_double(data, i)
end

deserializers[VARINT] = function(data, _, i)
  return read_varint(data, i)
end

deserializers[VARINT_NEGATIVE] = function(data, _, i)
  local result
  result, i = read_varint(data, i)
  return -result, i
end

deserializers[STRING] = function(data, _, i)
  return read_string(data, i)
end

deserializers[BIG_STRING] = function(data, cache, i)
  local cache_id
  cache_id, i = read_varint(data, i)

  local size
  size, i = read_varint(data, i)

  local result = data:sub(i, i + size - 1)
  cache[cache_id] = result
  return result, i + size
end

deserializers[TABLE] = function(data, cache, i)
  local cache_id
  cache_id, i = read_varint(data, i)

  local size
  size, i = read_varint(data, i)

  local result = {}
  cache[cache_id] = result

  for _ = 1, size do
    local k, v
    k, i = deserialize(data, cache, i)
    v, i = deserialize(data, cache, i)
    result[k] = v
  end

  return result, i
end

deserializers[TABLE_WITH_METATABLE] = function(data, cache, i)
  local result
  result, i = deserializers[TABLE](data, cache, i)

  local mt
  mt, i = deserialize(data, cache, i)

  return setmetatable(result, mt), i
end

deserializers[FUNCTION] = function(data, cache, i)
  local cache_id
  cache_id, i = read_varint(data, i)

  local dump
  dump, i = read_string(data, i)

  local result = assert(load(dump))
  cache[cache_id] = result

  local upvalues_n
  upvalues_n, i = read_varint(data, i)

  for j = 1, upvalues_n do
    local upvalue_cache_id
    upvalue_cache_id, i = read_varint(data, i)

    local upvalue
    upvalue, i = deserialize(data, cache, i)
    debug.setupvalue(result, j, upvalue)

    if upvalue_cache_id ~= 0 then
      -- TODO warning/error when deserializing id ~= 0 on lua with no debug.upvalueid
      local tuple = cache[upvalue_cache_id]
      if tuple then
        local f, f_i = unpack(tuple)
        debug.upvaluejoin(result, j, f, f_i)
      else
        cache[upvalue_cache_id] = {result, j}
      end
    end
  end

  return result, i
end

deserializers[REF] = function(data, cache, i)
  local id
  id, i = read_varint(data, i)
  return cache[id], i
end

deserializers[CODE] = function(data, _, i)
  local code
  code, i = read_string(data, i)
  -- TODO handle parsing errors
  return load("return " .. code)(), i
end

lump_mt.__call = function(_, value)
  return ("return require(%q).deserialize(%q)"):format(lump_modpath, lump.serialize(value))
end

--- @param value any
--- @return string
lump.serialize = function(value)
  local result = {string.byte("LUMP", 1, 4)}
  serialize(result, {size = 0}, value)

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

  local result, end_i = deserialize(data, {}, 5)
  if end_i ~= #data + 1 then
    error(("Read %s bytes, got %s total"):format(end_i - 1, #data))
  end
  return result
end

lump.serializer = setmetatable({}, {
  __call = function(self, x)
  end,
})

return lump
