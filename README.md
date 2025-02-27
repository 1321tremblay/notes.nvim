# notes.nvim

A basic note taking plugin that could be replace with a couple of line of configuration

<!-- TOC -->

- [Requirements](#requirements)
- [Installation](#installation)

<!-- TOC -->

## Requirement

- Optional
  - [oil.nvim] (https://github.com/stevearc/oil.nvim)
  - [telescope.nvim] (https://github.com/nvim-telescope/telescope.nvim)

## Installation

currently only tested on lazy.nvim

```lua
  {
    "1321tremblay/notes.nvim",
    dependencies = {
      -- "https://github.com/stevearc/oil.nvim"
      -- "https://github.com/nvim-telescope/telescope.nvim"
    },

  },

```

## Quickstart

Add this to your init.lua

```lua
require("notes").setup()
```

Then use :Notes open inside a file to open the notes directory which default to $HOME/notes.nvim/.

You can then use :Notes close to go back where you where.

Use :Notes todo to open todo.md inside the notes directory.
Upcoming features: Set up todo in a subdirectory to set daily todo and a main one.

Use :Notes search to open up telescope.nvim in the notes directory

## Options

If using the oil.nvim file explorer it will default to your own config if you have one.
Upcoming feature: Make a plugin scoped config possible as I learn how to override and restore user config.

```lua
  {
    "1321tremblay/notes.nvim",

    config = function()
      require("notes").setup({
        -- notes_dir = "path/to/notes", default to "$HOME/notes.nvim" 
        -- file_explorer = "oil" If oil is not set this will default to netrw.
        -- todo_file = "todo file name" default to "todo.md"
      })

      -- key mappings using plug
      vim.keymap.set("n", "<leader>no", "<Plug>(OpenNotes)", { desc = "[N]otes [O]pen" })
      vim.keymap.set("n", "<leader>nc", "<Plug>(CloseNotes)", { desc = "[N]otes [C]lose" })
      vim.keymap.set("n", "<leader>nt", "<Plug>(OpenTodo)", { desc = "[N]otes [T]odo" })
      vim.keymap.set("n", "<leader>ns", "<Plug>(SearchNotes)", { desc = "[N]otes [S]earch" })
      
      -- Key mappings using subcommands
      vim.keymap.set("n", "<leader>no", function()
        vim.cmd "Notes open"
      end, { desc = "[N]otes [O]pen" })
      vim.keymap.set("n", "<leader>nc", function()
        vim.cmd "Notes close"
      end, { desc = "[N]otes [C]lose" })
      vim.keymap.set("n", "<leader>nt", function()
        vim.cmd "Notes todo"
      end, { desc = "[N]otes [T]odo" })
      vim.keymap.set("n", "<leader>ns", function()
        vim.cmd "Notes search"
      end, { desc = "[N]otes [S]earch" })

    end,
  },

```


