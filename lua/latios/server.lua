local context = require('latios.context')
local config = require('latios.config')
local curl = require('plenary.curl')

local M = {}

-- Cache for completions
local completion_cache = {}

-- Rate limiting variables
local last_request_time = 0
local rate_limit_ms = 1000 -- 1 request per second

-- function M.request_completion(context, callback)
--   -- This is a placeholder. In a real implementation, you'd make an HTTP request to your AI service.
--   -- For demonstration, we'll use a timer to simulate an async operation.
--   vim.defer_fn(function()
--     local completion = "Example completion for: " .. context
--     callback(completion)
--   end, 100)
-- end

local function construct_prompt(full_context)
  local prompt = "You are an AI programming assistant. "
  prompt = prompt .. "The current file type is " .. full_context.filetype .. ". "
  prompt = prompt ..
      "The cursor is at position " .. full_context.cursor_position[1] .. ":" .. full_context.cursor_position[2] .. ". "

  -- Add LSP context
  if full_context.lsp.hover_info then
    prompt = prompt .. "The symbol under cursor is: " .. vim.inspect(full_context.lsp.hover_info) .. ". "
  end
  if full_context.lsp.signature_help then
    prompt = prompt .. "The current function signature is: " .. vim.inspect(full_context.lsp.signature_help) .. ". "
  end

  -- Add Tree-sitter context
  prompt = prompt .. "The syntactic context is: "
  for _, node in ipairs(full_context.treesitter) do
    prompt = prompt .. node.type .. " (" .. node.text .. "), "
  end

  -- Add surrounding code context
  prompt = prompt .. "Here are the surrounding lines of code:\n"
  local lines = full_context.buffer_content
  local cursor_line = full_context.cursor_position[1]
  local start_line = math.max(1, cursor_line - 5)
  local end_line = math.min(#lines, cursor_line + 5)

  for i = start_line, end_line do
    prompt = prompt .. lines[i] .. "\n"
  end

  prompt = prompt .. "Please provide a code completion for the current position."

  return prompt
end


local function handle_api_error(status, body)
  vim.schedule(function()
    if status == 401 then
      vim.notify("Latios: Invalid API key. Please check your configuration.", vim.log.levels.ERROR)
    elseif status == 429 then
      vim.notify("Latios: Rate limit exceeded. Please try again later.", vim.log.levels.WARN)
    else
      vim.notify("Latios: API error " .. status .. ". " .. body, vim.log.levels.ERROR)
    end
  end)
end

local function respect_rate_limit(callback)
  local current_time = vim.loop.now()
  local time_since_last_request = current_time - last_request_time

  if time_since_last_request < rate_limit_ms then
    local wait_time = rate_limit_ms - time_since_last_request
    vim.defer_fn(callback, wait_time)
  else
    callback()
  end

  last_request_time = current_time
end

-- Function to make the API request
-- local function request_anthropic_completion(prompt, callback)
--   local body = vim.fn.json_encode({
--     prompt = prompt,
--     model = "claude-v1", -- or whichever model you're using
--     max_tokens_to_sample = 300,
--     stop_sequences = { "\n\nHuman:" },
--     temperature = 0.8,
--   })
--
--   local headers = {
--     { "Content-Type", "application/json" },
--     { "X-API-Key",    config.options.anthropic_api_key },
--   }
--
--   coroutine.wrap(function()
--     local res, body = http.request("POST", "https://api.anthropic.com/v1/complete", headers, body)
--     if res.code == 200 then
--       local response = vim.fn.json_decode(body)
--       callback(response.completion)
--     else
--       print("Error from Anthropic API:", res.code, body)
--       callback(nil)
--     end
--   end)()
-- end


local function request_anthropic_completion(prompt, callback)
  respect_rate_limit(function()
    curl.post("https://api.anthropic.com/v1/complete", {
      headers = {
        ["Content-Type"] = "application/json",
        ["X-API-Key"] = config.options.anthropic_api_key
      },
      body = vim.fn.json_encode({
        prompt = prompt,
        model = "claude-v1",
        max_tokens_to_sample = 300,
        stop_sequences = { "\n\nHuman:" },
        temperature = 0.8,
      }),
      callback = function(response)
        if response.status == 200 then
          local body = vim.fn.json_decode(response.body)
          callback(body.completion)
        else
          vim.schedule(function()
            print("Error from Anthropic API:", response.status, response.body)
          end)
          callback(nil)
        end
      end
    })
  end)
end

local function get_cached_or_request(prompt, callback)
  if completion_cache[prompt] then
    callback(completion_cache[prompt])
  else
    request_anthropic_completion(prompt, callback)
  end
end

function M.request_completion(callback)
  local full_context = context.get_full_context()
  local prompt = construct_prompt(full_context)


  get_cached_or_request(prompt, function(completion)
    if completion then
      callback(completion)
    else
      vim.schedule(function()
        vim.notify("Latios: Failed to get completion from Anthropic", vim.log.levels.WARN)
        -- print("Failed to get completion from Anthropic")
      end)
      -- print("Failed to get completion from Anthropic API")
    end
  end)

  -- request_anthropic_completion(prompt, function(completion)
  --   if completion then
  --     callback(completion)
  --   else
  --     vim.schedule(function()
  --       print("Failed to get completion from Anthropic")
  --     end)
  --     -- print("Failed to get completion from Anthropic API")
  --   end
  -- end)

  -- Send this context to your AI service
  -- This is a placeholder for the actual API call
  -- vim.schedule(function()
  --   local completion = "AI completion based on context"
  --   callback(completion)
  -- end)
  -- vim.defer_fn(function()
  --   local completion = "Example completion for: " .. context
  --   callback(completion)
  -- end, 100)
end

return M
