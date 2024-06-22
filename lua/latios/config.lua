local M = {}

local default_config = {
  enabled = true,
  api_key = "",
  max_lines = 100,
  debounce_ms = 300,
}


M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", default_config, opts or {})
  if M.options.api_keu ~= "" then
  end
end

return M
