local M = {}

local default_config = {
  api_key = "",
  debounce_ms = 500,
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", default_config, opts or {})
end

return M
