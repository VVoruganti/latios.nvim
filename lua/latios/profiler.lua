-- lua/latios/profiler.lua
local M = {}

M.profiles = {}
M.is_active = false

function M.start()
  M.is_active = true
  M.profiles = {}
end

function M.stop()
  M.is_active = false
end

function M.profile(name, fn)
  return function(...)
    if not M.is_active then
      return fn(...)
    end

    local start_time = vim.loop.hrtime()
    local result = { fn(...) }
    local end_time = vim.loop.hrtime()

    local duration = (end_time - start_time) / 1e6 -- Convert to milliseconds
    if not M.profiles[name] then
      M.profiles[name] = { count = 0, total_time = 0 }
    end
    M.profiles[name].count = M.profiles[name].count + 1
    M.profiles[name].total_time = M.profiles[name].total_time + duration

    return unpack(result)
  end
end

local stack = {}

function M.start_span(name)
  if not M.is_active then return end
  local span = { name = name, start_time = vim.loop.hrtime(), children = {} }
  table.insert(stack, span)
end

function M.end_span()
  if not M.is_active then return end
  local span = table.remove(stack)
  if span then
    span.end_time = vim.loop.hrtime()
    span.duration = (span.end_time - span.start_time) / 1e6 -- Convert to milliseconds
    if #stack > 0 then
      table.insert(stack[#stack].children, span)
    else
      table.insert(M.profiles, span)
    end
  end
end

function M.report()
  local function print_span(span, depth)
    local indent = string.rep("  ", depth)
    print(string.format("%s%s: %.2f ms", indent, span.name, span.duration))
    for _, child in ipairs(span.children) do
      print_span(child, depth + 1)
    end
  end

  print("Profiling Report:")
  for _, span in ipairs(M.profiles) do
    print_span(span, 0)
  end
end

-- function M.report()
--   local sorted_profiles = {}
--   for name, data in pairs(M.profiles) do
--     table.insert(sorted_profiles, { name = name, count = data.count, total_time = data.total_time })
--   end
--
--   table.sort(sorted_profiles, function(a, b) return a.total_time > b.total_time end)
--
--   local report = "Profiling Report:\n"
--   for _, profile in ipairs(sorted_profiles) do
--     report = report .. string.format("%s: %d calls, %.2f ms total, %.2f ms avg\n",
--       profile.name, profile.count, profile.total_time, profile.total_time / profile.count)
--   end
--
--   print(report)
-- end

return M
