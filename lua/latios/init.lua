local M = {}
local server = require('latios.server')
local display = require('latios.display')
local utils = require('latios.utils')
local config = require('latios.config')
local bug = require('latios.debug')

local debounce_timer = nil
local debounce_delay = 300
local is_insert_mode = false

function M.setup(opts)
  require('latios.config').setup(opts)

  debounce_delay = config.options.debounce_ms

  vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI", "CompleteChanged" }, {
    callback = function()
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        is_insert_mode = true
        M.debounced_completion()
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'InsertLeave', 'BufUnload' }, {
    callback = function()
      is_insert_mode = false
      if vim.g.latios_enabled and not utils.is_telescope_buffer() then
        if debounce_timer then
          debounce_timer:stop()
          debounce_timer:close()
          debounce_timer = nil
        end
        display.clear_completion()
      end
    end,
  })
  -- vim.api.nvim_create_autocmd("CursorMovedI", {
  --   callback = function()
  --     if is_insert_mode and vim.g.latios_enabled and not utils.is_telescope_buffer() then
  --       display.clear_completion()
  --       M.debounced_completion()
  --     end
  --   end,
  -- })
  -- vim.api.nvim_create_autocmd("BufUnload", {
  --   pattern = "*",
  --   callback = function()
  --     if debounce_timer then
  --       debounce_timer:stop()
  --       debounce_timer:close()
  --       debounce_timer = nil
  --     end
  --   end,
  -- })
end

local function trigger_completion()
  if is_insert_mode then
    server.request_completion(function(completion)
      if is_insert_mode then
        display.show_completion(completion)
      end
    end)
  else
    display.clear_completion()
  end
end

function M.debounced_completion()
  display.clear_completion()
  if debounce_timer then
    debounce_timer:stop()
  end

  debounce_timer = vim.loop.new_timer()
  debounce_timer:start(debounce_delay, 0, vim.schedule_wrap(function()
    if is_insert_mode then
      trigger_completion()
    else
      display.clear_completion()
    end
    debounce_timer:close()
    debounce_timer = nil
  end))
end

return M
