local M = {}

function M.show_completion(completion)
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1 -- API uses 0-based line numbers

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
    virt_text = { { completion, 'LatiosCompletion' } },
    virt_text_pos = 'overlay',
  })
end

return M
