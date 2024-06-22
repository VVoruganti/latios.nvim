if vim.g.loaded_latios then
  return
end

vim.g.loaded_latios = true

-- Set up any global variables or initial configurations here
vim.g.latios_enabled = true

vim.api.nvim_create_user_command('Latios', function(opts)
  require('latios.commands').handle_command(opts.args)
end, {
  nargs = '*',
  complete = function(_, line)
    local commands = { 'enable', 'disable', 'toggle' }
    return vim.tbl_filter(function(cmd)
      return cmd:match('^' .. line)
    end, commands)
  end
})

-- Load the main module
require('latios').setup()
