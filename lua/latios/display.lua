local M = {}
local current_extmark_id = nil

-- local highlight_options = {
--   default = {
--     virt_text = { { completion, 'LatiosCompletion' } },
--     virt_text_pos = 'overlay',
--     hl_mode = 'combine',
--   },
--   treesitter = {
--     virt_text = { { completion, '@text.note' } },
--     virt_text_pos = 'overlay',
--     hl_mode = 'combine',
--   },
--   comment = {
--     virt_text = { { completion, 'Comment' } },
--     virt_text_pos = 'overlay',
--     hl_mode = 'combine',
--   },
--   custom = {
--     virt_text = { { completion, 'LatiosCustom' } },
--     virt_text_pos = 'overlay',
--     hl_mode = 'combine',
--   }
-- }

function M.show_completion(completion)
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1 -- API uses 0-based line numbers

  -- Clear the previous extmark if it exists
  if current_extmark_id then
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, current_extmark_id)
  end

  -- Set the new extmark and store its ID
  current_extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, {
    virt_text = { { completion, 'Comment' } },
    virt_text_pos = 'overlay',
    hl_mode = 'combine',
  })
end

function M.clear_completion()
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')

  if current_extmark_id then
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, current_extmark_id)
    current_extmark_id = nil
  end
end

function M.accept_completion()
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')

  if current_extmark_id then
    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, current_extmark_id, { details = true })
    if extmark and extmark[3] and extmark[3].virt_text then
      local completion_text = extmark[3].virt_text[1][1]
      local line, col = unpack(extmark)

      -- Insert the completion text
      vim.api.nvim_buf_set_text(bufnr, line, col, line, col, { completion_text })

      -- Move the cursor to the end of the inserted text
      local new_col = col + #completion_text
      vim.api.nvim_win_set_cursor(0, { line + 1, new_col })

      -- Ensure we're in insert mode at the end of the inserted text
      vim.cmd('startinsert!')
    end
    M.clear_completion()
  end
end

return M
