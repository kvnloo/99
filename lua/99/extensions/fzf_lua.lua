-- Compatibility shim for existing user keymaps.
-- New configurations should use 99.extensions.pickers directly.
local pickers = require("99.extensions.pickers")

return {
  select_model = pickers.select_model,
  select_provider = pickers.select_provider,
}
