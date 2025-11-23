local fw = require("tests.fw")
local lump = require("init")

fw.test("basic internal marking", function()
  local marked_module = require("tests.resources.marked_const_module")
  fw.assert_equal(marked_module, fw.pass(marked_module))
  fw.assert_equal(marked_module.table, fw.pass(marked_module.table))
  fw.assert_equal(marked_module.coroutine, fw.pass(marked_module.coroutine))
end)

fw.test("internal marking with a schema", function()
  local marked_module = require("tests.resources.marked_module")
  fw.assert_equal(marked_module, fw.pass(marked_module))
  fw.assert_equal(marked_module.table, fw.pass(marked_module.table))
  fw.assert_equal(marked_module.table.inner, fw.pass(marked_module.table.inner))
  fw.assert_equal(marked_module.table2, fw.pass(marked_module.table2))
  assert(marked_module.table2.inner ~= fw.pass(marked_module.table2.inner))
  fw.assert_equal(marked_module.coroutine, fw.pass(marked_module.coroutine))
end)

fw.test("marking from the outside", function()
  local deterministic = require("tests.resources.deterministic")
  lump.mark_module("tests.resources.deterministic", {})
  fw.assert_equal(deterministic, fw.pass(deterministic))
  assert(deterministic.some_value ~= fw.pass(deterministic.some_value))

  lump.serializer.handlers[deterministic] = nil
end)

fw.test("const shouldn't leak into function upvalues, may begin to mark dependencies", function()
  lump.mark_module("tests.resources.leak_dependent", "const")
end)

fw.test("upvalues can be marked manually", function()
  local ok = pcall(lump.mark_module, "tests.resources.leak_dependent", {
    f = {
      dependency = "const",
    }
  })

  fw.assert_equal(ok, false)
end)
