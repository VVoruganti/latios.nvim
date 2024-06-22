local M = {}

function M.setup(opts)
  require('latios.config').setup(opts)

  vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
    callback = function()
      if vim.g.latios_enabled then
        M.trigger_completion()
      end
    end,
  })
end

function M.trigger_completion()
  local context = require('latios.utils').get_current_line_context()
  require('latios.server').request_completion(context, function(completion)
    if completion then
      require('latios.utils').display_completion(completion)
    end
  end)
end

return M
