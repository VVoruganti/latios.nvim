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
  if completion == 'nil' then return end
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  line = line - 1 -- API uses 0-based line numbers

  -- Clear the previous extmark if it exists
  if current_extmark_id then
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, current_extmark_id)
  end

  -- Split the completion into lines
  local lines = vim.split(completion, '\n', true)

  -- Remove the last line if it's empty
  if lines[#lines] == '' then
    table.remove(lines, #lines)
  end
  local opts = {
    virt_text = { { lines[1], 'Comment' } },
    virt_text_pos = 'overlay',
    hl_mode = 'combine',

  }

  -- If there are additional lines, add them as virt_lines
  if #lines > 1 then
    opts.virt_lines = {}
    for i = 2, #lines do
      table.insert(opts.virt_lines, { { lines[i], 'Comment' } })
    end
  end

  -- Set the new extmark and store its ID
  current_extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col, opts)
end

function M.clear_completion()
  if current_extmark_id then
    local bufnr = vim.api.nvim_get_current_buf()
    local ns_id = vim.api.nvim_create_namespace('latios')
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, current_extmark_id)
    current_extmark_id = nil
  end
end

function M.accept_completion()
  local bufnr = vim.api.nvim_get_current_buf()
  local ns_id = vim.api.nvim_create_namespace('latios')

  if current_extmark_id then
    local extmark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns_id, current_extmark_id, { details = true })
    if extmark and extmark[3] then
      local line, col = unpack(extmark)
      local completion_lines = {}

      -- Get the first line from virt_text
      if extmark[3].virt_text then
        table.insert(completion_lines, extmark[3].virt_text[1][1])
      end

      -- Get additional lines from virt_lines
      if extmark[3].virt_lines then
        for _, virt_line in ipairs(extmark[3].virt_lines) do
          table.insert(completion_lines, virt_line[1][1])
        end
      end

      -- Insert the completion text
      local current_line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
      local prefix = string.sub(current_line_text, 1, col)
      local suffix = string.sub(current_line_text, col + 1)

      local new_lines = { prefix .. completion_lines[1] }
      for i = 2, #completion_lines do
        table.insert(new_lines, completion_lines[i])
      end
      new_lines[#new_lines] = new_lines[#new_lines] .. suffix

      -- Replace the current line and add new lines if necessary
      vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, new_lines)

      -- Move the cursor to the end of the inserted text
      local end_line = line + #new_lines - 1
      local end_col = #new_lines[#new_lines] - #suffix

      vim.api.nvim_win_set_cursor(0, { end_line + 1, end_col })

      vim.cmd('startinsert!')
    end
    M.clear_completion()
  end
end

return M
