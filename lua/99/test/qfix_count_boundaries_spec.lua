-- luacheck: globals describe it assert
local QFixHelpers = require("99.ops.qfix-helpers")
local eq = assert.are.same

describe("quickfix count boundaries", function()
  it("rejects a count followed by prose or punctuation", function()
    eq(nil, QFixHelpers.parse_line("src/a.lua:12:3,1broken"))
    eq(nil, QFixHelpers.parse_line("src/a.lua:12:3,0oops"))
    eq(nil, QFixHelpers.parse_line("src/a.lua:12:3,1;diagnostic"))
  end)

  it("rejects an empty filename", function()
    eq(nil, QFixHelpers.parse_line(":12:3,1,detail"))
  end)

  it("keeps valid count and diagnostic variants", function()
    eq("", QFixHelpers.parse_line("src/a.lua:12:3,1").text)
    eq("", QFixHelpers.parse_line("src/a.lua:12:3,1,").text)
    eq("hello,a,b", QFixHelpers.parse_line("src/a.lua:12:3,1,hello,a,b").text)
    eq("C:/repo/a.lua", QFixHelpers.parse_line("C:/repo/a.lua:12:3,1,ok").filename)
  end)

  it("never puts malformed counts in quickfix entry lists", function()
    local entries = QFixHelpers.create_qfix_entries(table.concat({
      "src/valid.lua:2:1,1,first",
      "src/invalid.lua:3:1,1broken",
      "src/other.lua:5:1,1,second",
    }, "\n"))
    eq(2, #entries)
    eq("src/valid.lua", entries[1].filename)
    eq("src/other.lua", entries[2].filename)
  end)
end)
