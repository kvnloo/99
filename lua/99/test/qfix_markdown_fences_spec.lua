-- luacheck: globals describe it assert
local eq = assert.are.same
local normalize = require("99.providers").CursorAgentProvider.normalize_qfix_response

describe("CursorAgent Markdown fence boundaries", function()
  it("ignores quickfix-like text in tilde fences", function()
    local text = table.concat({
      "~~~lua",
      "src/fake.lua:1:1,1,ignore",
      "~~~",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("does not treat a citation inside a tilde fence as a hit", function()
    local text = table.concat({
      "~~~markdown",
      "```4:7:src/fake.lua",
      "~~~",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("does not close a four-backtick fence with three backticks", function()
    local text = table.concat({
      "````markdown",
      "```",
      "src/fake.lua:3:1,1,ignore",
      "````",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("does not close a fence with a same-length info string", function()
    local text = table.concat({
      "```typescript",
      "```typescript",
      "src/fake.lua:8:1,1,ignore",
      "```",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("accepts trailing whitespace on a valid closing fence", function()
    local text = table.concat({
      "~~~lua",
      "src/fake.lua:8:1,1,ignore",
      "~~~  ",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("preserves citation ordering with a normal closing fence", function()
    local text = table.concat({
      "src/a.lua:1:1,1,first",
      "```5:7:src/b.lua",
      "src/inside.lua:8:1,1,ignore",
      "```",
      "src/c.lua:3:2,1,last",
    }, "\n")
    eq(
      "src/a.lua:1:1,1,first\nsrc/b.lua:5:1,3,match\nsrc/c.lua:3:2,1,last",
      normalize(text)
    )
  end)

  it("does not close a tilde fence with backticks", function()
    local text = table.concat({
      "~~~markdown",
      "```",
      "src/fake.lua:9:1,1,ignore",
      "~~~",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("accepts a longer matching closing fence", function()
    local text = table.concat({
      "````lua",
      "src/fake.lua:9:1,1,ignore",
      "`````",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("keeps the first representation of a duplicate citation location", function()
    local text = table.concat({
      "src/a.lua:4:1,1,original context",
      "```4:6:src/a.lua",
      "src/fake.lua:9:1,1,ignore",
      "```",
      "src/a.lua:4:2,1,different column",
    }, "\n")
    eq(
      "src/a.lua:4:1,1,original context\nsrc/a.lua:4:2,1,different column",
      normalize(text)
    )
  end)

  it("ignores code in an unclosed fence", function()
    local text = table.concat({
      "src/real.lua:2:1,1,keep",
      "```typescript",
      "src/fake.lua:1:1,1,ignore",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("does not treat a four-space-indented citation as a fence", function()
    local text = table.concat({
      "    ```4:6:src/fake.lua",
      "src/real.lua:2:1,1,keep",
    }, "\n")
    eq("src/real.lua:2:1,1,keep", normalize(text))
  end)

  it("rejects free-form prose containing nonnumeric quickfix fields", function()
    local text = table.concat({
      "Summary: no matches: none,found",
      "src/bad-line.lua:line:3,1,drop",
      "src/bad-col.lua:12:col,1,drop",
      "src/bad-count.lua:12:3,count,drop",
      "src/bad-suffix.lua:12:3,1broken",
      "src/valid.lua:12:3,1,keep",
    }, "\n")
    eq("src/valid.lua:12:3,1,keep", normalize(text))
  end)

  it("keeps two Windows paths with different positions", function()
    local text = "C:/repo/a.lua:10:2,1,first\nC:/repo/b.lua:11:3,1,second"
    eq(text, normalize(text))
  end)

  it("deduplicates identical Windows locations by numeric suffix", function()
    local text = "C:/repo/a.lua:10:2,1,first\nC:/repo/a.lua:10:2,1,duplicate"
    eq("C:/repo/a.lua:10:2,1,first", normalize(text))
  end)

  it("keeps separate files with colons in Unix filenames", function()
    local text = "src/a:one.lua:12:3,1,first\nsrc/a:two.lua:13:3,1,second"
    eq(text, normalize(text))
  end)

  it("accepts a numeric quickfix line without description", function()
    eq("src/valid.lua:12:3,1", normalize("src/valid.lua:12:3,1"))
  end)

end)
