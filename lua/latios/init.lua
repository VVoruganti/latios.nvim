local M = {}
local server = require('latios.server')
local display = require('latios.display')
local utils = require('latios.utils')

function M.setup(opts)
  require('latios.config').setup(opts)

  vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "CompleteChanged" }, {
    callback = function()
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        server.debounced_request_completion(function(completion)
          if completion then
            display.show_completion(completion)
          end
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufUnload' }, {
    callback = function()
      is_insert_mode = false
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        server.cancel_ongoing_requests()
        display.clear_completion()
      end
    end,
  })
end

return M
