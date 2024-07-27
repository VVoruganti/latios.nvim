# Latios

Latios is an AI-powered code completion plugin for Neovim.

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/latios',
  config = function()
    require('latios').setup({
      api_key = "your-api-key",
    })
  end
}
```

## Usage

Latios will automatically provide completions as you type. You can also use the following commands:

* `:Latios enable` - Enable Latios completions
* `:Latios disable` - Disable Latios completions
* `:Latios toggle` - Toggle Latios completions on or off

## Configuration

You can configure Latios by calling the setup function:

```lua
require('latios').setup({
  api_key = "your-api-key",
  debounce_ms = 500,
})
```

## Performance Notes

Currently, it is able to generate completions and has the ergonomics of a
co-pilot. There is some issue with lag especially in markdown files for whatever
reason. 

IT doesn't do a great job of "completing" or generating the next token and can
instead generate existing tokens. Such as if you write "local var = " expecting
it to just complete the remaining output it will often generate the entire
variable declaration again or repeat part of the existing code. 

Another issue is that the completions may not always be context-aware,
especially when dealing with complex code structures or domain-specific
languages. This can result in suggestions that are syntactically correct but
semantically incorrect or irrelevant to the current context.


## License

MIT
