local context = require('latios.context')
local config = require('latios.config')
local curl = require('plenary.curl')
local bug = require('latios.debug')

local M = {}

local function construct_prompt(full_context)
  -- System prompt
  local system_prompt = [[
  You are an AI programming assistant specialized in providing code completions
  and explanations. Your responses should be concise, relevant, and tailored to
  the specific programming context provided. Do not provide any explanation or
  styling only the code itself. Do not talk at all. Only output valid code. Do
  not provide any backticks that surround the code. Never ever output backticks
  like this ```.]]

  -- local prompt = "You are an AI programming assistant. "
  local prompt = string.format("I'm working on a %s file: %s. ",
    full_context.filetype,
    full_context.file_path or "unknown path"
  )

  prompt = prompt .. string.format("My cursor is at position %d:%d. ",
    full_context.cursor_position[1],
    full_context.cursor_position[2]
  )
  -- "My cursor is at position " .. full_context.cursor_position[1] .. ":" .. full_context.cursor_position[2] .. ". "

  -- Add LSP context
  if full_context.lsp.hover_info then
    prompt = prompt .. "The symbol under cursor is: " .. tostring(full_context.lsp.hover_info) .. ". "
  end
  if full_context.lsp.signature_help then
    prompt = prompt .. "The current function signature is: " .. tostring(full_context.lsp.signature_help) .. ". "
  end

  -- Add Tree-sitter context
  if full_context.treesitter then
    prompt = prompt .. "Syntactic context: "
    for _, node in ipairs(full_context.treesitter) do
      prompt = prompt .. string.format("%s (%s), ", node.type, node.text)
      -- prompt = prompt .. node.type .. " (" .. node.text .. "), "
    end
  end

  -- Add surrounding code context
  local lines = full_context.buffer_content
  local cursor_line = full_context.cursor_position[1]
  local context_size = math.min(10, math.floor(#lines / 2)) -- Adjust based on file size
  local start_line = math.max(1, cursor_line - context_size)
  local end_line = math.min(#lines, cursor_line + context_size)

  prompt = prompt .. "Surrounding code:\n"

  for i = start_line, end_line do
    if i == cursor_line then
      prompt = prompt .. "> " .. lines[i] .. "\n" -- Highlight current line
    else
      prompt = prompt .. lines[i] .. "\n"
    end
    -- prompt = prompt .. lines[i] .. "\n"
  end

  -- Include function/class context if available
  if full_context.current_function then
    prompt = prompt .. "Current function:\n" .. full_context.current_function .. "\n"
  end

  -- Add language-specific context
  if full_context.language_specific then
    prompt = prompt .. "Language-specific context: " .. full_context.language_specific .. "\n"
  end

  prompt = prompt ..
      "Please provide a completion for the current position. If there is not a relevant completion output nil"

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
      -- model = "claude-3-haiku-20240307",
      model = "claude-3-5-sonnet-20240620",
      max_tokens = 100,
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

function M.request_completion(callback)
  local full_context = context.get_full_context()
  local prompt = construct_prompt(full_context)
  request_anthropic_completion(prompt, function(completion)
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
