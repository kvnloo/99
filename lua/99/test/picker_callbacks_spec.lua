-- luacheck: globals describe it assert
local eq = assert.are.same
local pickers = require("99.extensions.pickers")

local function with_stubs(overrides, callback)
  local originals = {}
  for name, replacement in pairs(overrides) do
    originals[name] = name == "ui_select" and vim.ui.select or pickers[name]
    if name == "ui_select" then
      vim.ui.select = replacement
    else
      pickers[name] = replacement
    end
  end
  local ok, err = pcall(callback)
  for name, original in pairs(originals) do
    if name == "ui_select" then
      vim.ui.select = original
    else
      pickers[name] = original
    end
  end
  assert(ok, err)
end

describe("legacy picker selector callbacks", function()
  for _, module_name in ipairs({ "telescope", "fzf_lua" }) do
    it(module_name .. " forwards model selection and cancel", function()
      local selected = {}
      local index = 0
      with_stubs({
        get_models = function(_provider, callback)
          callback({ "small", "large" }, "small")
        end,
        on_model_selected = function(model)
          selected[#selected + 1] = model
        end,
        ui_select = function(items, options, callback)
          eq({ "small", "large" }, items)
          eq("Choose model", options.prompt)
          index = index + 1
          callback(index == 1 and "large" or nil)
        end,
      }, function()
        local legacy = require("99.extensions." .. module_name)
        legacy.select_model({ prompt = "Choose model" })
        legacy.select_model({ prompt = "Choose model" })
      end)
      eq({ "large" }, selected)
    end)

    it(module_name .. " forwards provider choice and cancel", function()
      local selected = {}
      local provider = { _get_provider_name = function() return "Mock" end }
      local lookup = { Mock = provider }
      local index = 0
      with_stubs({
        get_providers = function()
          return { names = { "Mock" }, lookup = lookup, current = "Mock" }
        end,
        on_provider_selected = function(name, found)
          eq(lookup, found)
          selected[#selected + 1] = name
        end,
        ui_select = function(items, options, callback)
          eq({ "Mock" }, items)
          eq("Choose provider", options.prompt)
          index = index + 1
          callback(index == 1 and "Mock" or nil)
        end,
      }, function()
        local legacy = require("99.extensions." .. module_name)
        legacy.select_provider({ prompt = "Choose provider" })
        legacy.select_provider({ prompt = "Choose provider" })
      end)
      eq({ "Mock" }, selected)
    end)
  end
end)
