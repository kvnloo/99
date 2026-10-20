-- luacheck: globals describe it assert
local QFixHelpers = require("99.ops.qfix-helpers")
local eq = assert.are.same
local create_entries = QFixHelpers.create_qfix_entries

describe("qfix helpers", function()
  it("parse_line parses filename, line, column, range, and notes", function()
    local parsed = QFixHelpers.parse_line(
      "lua/99/ops/search.lua:42:7,3,found semantic search"
    )

    eq({
      filename = "lua/99/ops/search.lua",
      lnum = 42,
      col = 7,
      text = "found semantic search",
    }, parsed)
  end)

  it("parse_line keeps commas in notes text", function()
    local parsed = QFixHelpers.parse_line("file.lua:10:3,1,note,with,commas")

    assert(parsed)
    eq("file.lua", parsed.filename)
    eq(10, parsed.lnum)
    eq(3, parsed.col)
    eq("note,with,commas", parsed.text)
  end)

  it("parse_line returns nil for malformed lines", function()
    eq(nil, QFixHelpers.parse_line("file.lua:10"))
    eq(nil, QFixHelpers.parse_line("file.lua:10:3:extra"))
    eq(nil, QFixHelpers.parse_line("file.lua:10:3"))
  end)

  it("parse_line keeps colons in notes text", function()
    local parsed =
      QFixHelpers.parse_line("file.lua:10:3,2,check this: important section")

    assert(parsed)
    eq("check this: important section", parsed.text)
  end)

  it(
    "create_qfix_entries parses valid lines and skips malformed ones",
    function()
      local response = table.concat({
        "a.lua:1:2,4,first hit",
        "not a valid line",
        "b.lua:3:4,1,",
        "c.lua:5:7,2,fallback values",
        "",
      }, "\n")

      local locations = create_entries(response)

      eq({
        {
          filename = "a.lua",
          lnum = 1,
          col = 2,
          text = "first hit",
        },
        {
          filename = "b.lua",
          lnum = 3,
          col = 4,
          text = "",
        },
        {
          filename = "c.lua",
          lnum = 5,
          col = 7,
          text = "fallback values",
        },
      }, locations)
    end
  )

  it("create_qfix_entries returns empty list for empty response", function()
    eq({}, create_entries(""))
  end)

  it("preserves Windows drive paths through entry conversion", function()
    local entries = create_entries(table.concat({
      "C:/repo/file.lua:10:2,1,first",
      "C:\\repo\\file.lua:12:5,2,second",
    }, "\n"))
    eq({
      { filename = "C:/repo/file.lua", lnum = 10, col = 2, text = "first" },
      { filename = "C:\\repo\\file.lua", lnum = 12, col = 5, text = "second" },
    }, entries)
  end)

  it("preserves colons in filenames and diagnostic notes", function()
    local entries = create_entries(table.concat({
      "src/a:one.lua:12:3,1,note:extra",
      "src/plain.lua:4:8,1,ordinary",
    }, "\n"))
    eq({
      { filename = "src/a:one.lua", lnum = 12, col = 3, text = "note:extra" },
      { filename = "src/plain.lua", lnum = 4, col = 8, text = "ordinary" },
    }, entries)
  end)

  it("preserves numeric-looking location markers inside diagnostics", function()
    local parsed =
      QFixHelpers.parse_line("src/errors.lua:8:5,1,value:8:3,2,description")
    assert(parsed)
    eq("src/errors.lua", parsed.filename)
    eq(8, parsed.lnum)
    eq(5, parsed.col)
    eq("value:8:3,2,description", parsed.text)
  end)

  it("rejects nonnumeric locations instead of inventing row 1 col 1", function()
    eq(nil, QFixHelpers.parse_line("src/raw.lua:bad:also_bad,1,note"))
    eq(nil, QFixHelpers.parse_line("src/raw.lua:line:3,1,note"))
    eq(nil, QFixHelpers.parse_line("summary:missing:matches,1,ignore"))
    local zero = QFixHelpers.parse_line("src/zero.lua:0:0,0,note")
    assert(zero)
    eq(0, zero.lnum)
    eq(0, zero.col)
  end)
end)
