local M = {}
local server = require('latios.server')
local display = require('latios.display')
local utils = require('latios.utils')
local bug = require('latios.debug')

function M.setup(opts)
  require('latios.config').setup(opts)

  vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
    callback = function()
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        M.trigger_completion()
      end
    end,
  })

  vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function()
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        display.clear_completion()
      end
    end,
  })
end

-- function M.trigger_completion()
--   local context = require('latios.utils').get_current_line_context()
--   require('latios.server').request_completion(context, function(completion)
--     if completion then
--       require('latios.utils').display_completion(completion)
--     end
--   end)
-- end


function M.trigger_completion()
  local config = require('latios.config')
  -- print(config)
  -- bug.debug_info(vim.inspect(config.options))
  -- bug.debug_info(config.options['max_line'])
  -- vim.schedule(function()
  --   print("Anthropic API:", config.options)
  -- end)
  display.show_completion("test")
  -- server.request_completion(function(completion)
  --   display.show_completion(completion)
  -- end)
end

return M
