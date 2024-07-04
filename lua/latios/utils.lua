local M = {}

function M.is_telescope_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  return filetype == 'TelescopePrompt'
end

function M.get_current_line_context()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(1, col)
end

function M.display_completion(completion)
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local col = vim.api.nvim_win_get_cursor(0)[2]

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
    virt_text = { { completion, 'Comment' } },
    virt_text_pos = 'overlay',
  })
end

return M
