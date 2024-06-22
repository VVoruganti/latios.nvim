-- In lua/latios/context.lua
local M = {}

function M.get_lsp_context()
  local context = {}

  -- Get current buffer diagnostics
  context.diagnostics = vim.lsp.diagnostic.get_line_diagnostics()

  -- Get symbol under cursor
  local params = vim.lsp.util.make_position_params()
  local result = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, 1000)
  if result and result[1] then
    context.hover_info = result[1].result
  end

  -- Get function signature if inside a function call
  local signature = vim.lsp.buf_request_sync(0, 'textDocument/signatureHelp', params, 1000)
  if signature and signature[1] then
    context.signature_help = signature[1].result
  end

  return context
end

-- In lua/latios/context.lua (continued)
function M.get_treesitter_context()
  local context = {}

  -- Ensure we have a parser for the current buffer
  local parser = vim.treesitter.get_parser(0)
  local tree = parser:parse()[1]
  local root = tree:root()

  -- Get the node at the cursor
  local cursor = vim.api.nvim_win_get_cursor(0)
  local node = root:named_descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])

  -- Traverse up the tree to get context
  while node do
    table.insert(context, { type = node:type(), text = vim.treesitter.get_node_text(node, 0) })
    node = node:parent()
  end

  return context
end

-- In lua/latios/context.lua (continued)
function M.get_full_context()
  return {
    lsp = M.get_lsp_context(),
    treesitter = M.get_treesitter_context(),
    -- Add any other context you want to include
    buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, false),
    cursor_position = vim.api.nvim_win_get_cursor(0),
    filetype = vim.bo.filetype,
  }
end

return M
