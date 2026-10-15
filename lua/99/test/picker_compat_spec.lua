-- luacheck: globals describe it assert
local eq = assert.are.same

describe("legacy picker module compatibility", function()
  local pickers = require("99.extensions.pickers")

  for _, name in ipairs({ "telescope", "fzf_lua" }) do
    it(name .. " delegates model and provider selectors", function()
      local legacy = require("99.extensions." .. name)
      eq(pickers.select_model, legacy.select_model)
      eq(pickers.select_provider, legacy.select_provider)
    end)
  end
end)
