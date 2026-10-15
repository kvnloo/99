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
end)
