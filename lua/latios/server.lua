local context = require('latios.context')
local config = require('latios.config')
local curl = require('plenary.curl')
local bug = require('latios.debug')

local M = {}

-- Cache for completions
local completion_cache = {}

-- Rate limiting variables
-- local last_request_time = 0
-- local rate_limit_ms = 1000 -- 1 request per second
--
-- local function handle_api_error(status, body)
--   vim.schedule(function()
--     if status == 401 then
--       vim.notify("Latios: Invalid API key. Please check your configuration.", vim.log.levels.ERROR)
--     elseif status == 429 then
--       vim.notify("Latios: Rate limit exceeded. Please try again later.", vim.log.levels.WARN)
--     else
--       vim.notify("Latios: API error " .. status .. ". " .. body, vim.log.levels.ERROR)
--     end
--   end)
-- end
--
-- local function respect_rate_limit(callback)
--   local current_time = vim.loop.now()
--   local time_since_last_request = current_time - last_request_time
--
--   if time_since_last_request > rate_limit_ms then
--     callback()
--     last_request_time = current_time
--   end
-- end

local function construct_prompt(full_context)
  -- System prompt
  local system_prompt =
  "You are an AI programming assistant specialized in providing code completions and explanations. Your responses should be concise, relevant, and tailored to the specific programming context provided. Do not provide any explanation or styling only the code itself."

  -- local prompt = "You are an AI programming assistant. "
  local prompt = "I'm working on a  " .. full_context.filetype .. " file."
  prompt = prompt ..
      "My cursor is at position " .. full_context.cursor_position[1] .. ":" .. full_context.cursor_position[2] .. ". "

  -- Add LSP context
  if full_context.lsp.hover_info then
    prompt = prompt .. "The symbol under cursor is: " .. vim.inspect(full_context.lsp.hover_info) .. ". "
  end
  if full_context.lsp.signature_help then
    prompt = prompt .. "The current function signature is: " .. vim.inspect(full_context.lsp.signature_help) .. ". "
  end

  -- Add Tree-sitter context
  if full_context.treesitter then
    prompt = prompt .. "The syntactic context is: "
    for _, node in ipairs(full_context.treesitter) do
      prompt = prompt .. node.type .. " (" .. node.text .. "), "
    end
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

  return {
    system_prompt = system_prompt,
    messages = {
      { role = "user", content = prompt }
    }
  }
end

local function request_anthropic_completion(prompt_data, callback)
  curl.post("https://api.anthropic.com/v1/messages", {
    headers = {
      ["Content-Type"] = "application/json",
      ["X-API-Key"] = config.options.api_key,
      ["Anthropic-Version"] = "2023-06-01"
    },
    body = vim.fn.json_encode({
      system = prompt_data.system_prompt,
      messages = prompt_data.messages,
      model = "claude-3-haiku-20240307",
      max_tokens = 300,
      stop_sequences = { "\n\nHuman:" },
      temperature = 0.8,
    }),
    callback = function(response)
      vim.schedule(function()
        if response.status == 200 then
          local body = vim.fn.json_decode(response.body)
          callback(body.content[1].text)
        else
          print("Error from Anthropic API:", response.status, response.body)
          callback(nil)
        end
      end)
    end
  })
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
      end)
    end
  end)
end

return M
