local lump = require("init")


local libraries = {
  {name = "lump", serialize = lump.serialize, deserialize = lump.deserialize},
  {name = "lump (compatible)", serialize = lump, deserialize = function(x) return load(x)() end},
}

local ok, ldump = pcall(require, "benchmarks.deps.ldump.init")
if ok then
  table.insert(libraries, {
    name = "ldump",
    serialize = ldump,
    deserialize = function(x) return load(x)() end,
  })
end

local cases = {}

do
  -- TODO 100000 is broken
  for _, gen in ipairs {
    {type = "integers", f = function(i) return 2 * i end},
    {type = "doubles", f = function(i) return 2 * i + .1 end},
    {type = "functions", f = function(i) return function() end end},
    {type = "tables", f = function(i) return {} end},
  } do
    local n = 100000
    local target = {}
    for i = 1, n do
      target[i] = gen.f(i)
    end
    table.insert(cases, {name = n .. " " .. gen.type, target = target})
  end
end

local padding do
  padding = 0
  for _, lib in ipairs(libraries) do
    padding = math.max(padding, #lib.name)
  end
end

for i, case in ipairs(cases) do
  print(case.name)
  print(("-"):rep(#case.name))

  for _, lib in ipairs(libraries) do
    local start_t = os.clock()

    local dump = lib.serialize(case.target)
    local serialize_t = os.clock() - start_t

    local _ = lib.deserialize(dump)
    local deserialize_t = os.clock() - serialize_t

    print(("%s%s\t%.3f ms\t%.3f ms\t%.3f ms\t%.3f KiB"):format(
      lib.name,
      (" "):rep(padding - #lib.name),
      serialize_t * 1000,
      deserialize_t * 1000,
      (serialize_t + deserialize_t) * 1000,
      #dump / 1024
    ))
  end

  if i < #cases then print() end
end
