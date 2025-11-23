local fw = require("tests.fw")

fw.run {
  "tests/test_primitives.lua",
  "tests/test_composites.lua",
}
