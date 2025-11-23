local fw = require("tests.fw")

fw.run {
  "tests/test_primitives.lua",
  "tests/test_composites.lua",
  "tests/test_ldump_compatibility.lua",
  "tests/test_edge_cases.lua",
  "tests/test_overrides.lua",
  "tests/test_mark.lua",
}
