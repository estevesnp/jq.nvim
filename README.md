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

      -- options: "up" | "down"
      jq_input_pos = "up",

      -- options: "tab" | "left" | "right"
      jq_output_pos = "right",

      -- default 'jq' query when opening input buffer
      default_expression = ".",
    })

    -- if you want a key bind using the lua API
    vim.keymap.set("n", "<leader>jq", require("jq").view_file)
  end
}
```

## usage

use either the `:JQ` command or the lua API with an optional filename (uses current file as default)

this will open a new tab with a buffer for your `jq` query and a buffer with the result being rendered

update the query and then save the buffer to re-render the output
