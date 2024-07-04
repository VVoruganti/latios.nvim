local M = {}

-- Debug levels
M.DEBUG = 1
M.INFO = 2
M.WARN = 3
M.ERROR = 4

-- Current debug level
M.current_level = M.INFO

-- Debug buffer name
M.debug_buf_name = 'LatiosDebug'

-- Debug file path
M.debug_file_path = vim.fn.stdpath('data') .. '/latios_debug.log'

-- Function to print to a buffer
function M.print_to_buffer(message, level)
  if level < M.current_level then return end

  local buf = vim.fn.bufnr(M.debug_buf_name)
  if buf == -1 then
    vim.cmd('new ' .. M.debug_buf_name)
    buf = vim.fn.bufnr(M.debug_buf_name)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  end

  local lines = vim.split(message, '\n')
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
end

-- Function to print to a file
function M.print_to_file(message, level)
  if level < M.current_level then return end

  local file = io.open(M.debug_file_path, 'a')
  if file then
    file:write(os.date('%Y-%m-%d %H:%M:%S ') .. message .. '\n')
    file:close()
  end
end

-- Function to print both to buffer and file
function M.debug(message, level)
  level = level or M.DEBUG
  M.print_to_buffer(message, level)
  M.print_to_file(message, level)
end

-- Convenience functions for different log levels
function M.debug_info(message) M.debug(message, M.INFO) end

function M.debug_warn(message) M.debug(message, M.WARN) end

function M.debug_error(message) M.debug(message, M.ERROR) end

return M
