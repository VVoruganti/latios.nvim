local M = {}

function M.request_completion(context, callback)
  -- This is a placeholder. In a real implementation, you'd make an HTTP request to your AI service.
  -- For demonstration, we'll use a timer to simulate an async operation.
  vim.defer_fn(function()
    local completion = "Example completion for: " .. context
    callback(completion)
  end, 100)
end

return M
