# jq.nvim

a [jq](https://github.com/jqlang/jq) visualizer inside nvim

## instalation

requires [jq](https://github.com/jqlang/jq) to be accessible through your path

with [lazy](https://github.com/folke/lazy.nvim) package manager:

```lua
{
  "estevesnp/jq.nvim",
  config = function()

    -- calling the 'setup' function is optional
    -- these are the default values
    require("jq").setup({

      -- options: "tab" | "left" | "right" | "inplace"
      buffer_pos = "right",

      -- options: "up" | "down"
      input_pos = "up",

      -- options: uint > 0
      input_height = 5,

      -- default 'jq' query when opening input buffer
      default_expression = ".",

      -- how errors are displayed
      -- options: "message" | "output"
      display_error = "message",
    })

    -- if you want a key bind using the lua API
    vim.keymap.set("n", "<leader>jq", require("jq").view_file)

    -- or if you want to pass certain options only for a keybind
    vim.keymap.set("n", "<leader>jt", function()
      require("jq").view_file({
        buffer_pos = "tab",
        input_pos = "down",
        input_height = 10,
        display_error = "output",
      })
    end)

  end
}
```

## usage

use either the `:JQ` command or the lua API with an optional filename (uses current file as default)

you can also pass options to the user command, like `:JQ buffer_pos=left input_pos=down ../foo.json`

this will open a new tab with a buffer for your `jq` query and a buffer with the result being rendered

update the query and then save the buffer to re-render the output
