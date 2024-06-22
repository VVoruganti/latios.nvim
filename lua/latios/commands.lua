local M = {}

function M.handle_command(args)
  if args == "enable" then
    M.enable()
  elseif args == "disable" then
    M.disable()
  elseif args == "toggle" then
    M.toggle()
  else
    print("Unknown Latios command. Available commands: enable, disable, toggle")
  end
end

function M.enable()
  vim.g.latios_enabled = true
  print("Latios enabled")
end

function M.disable()
  vim.g.latios_enabled = false
  print("Latios disabled")
end

function M.toggle()
  vim.g.latios_enabled = not vim.g.latios_enabled
  print("Latios " .. (vim.g.latios_enabled and "enabled" or "disabled"))
end

return M
