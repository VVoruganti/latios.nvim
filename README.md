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
  max_lines = 150,
  debounce_ms = 250,
})
```

## License

MIT
