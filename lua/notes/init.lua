local M = {}

local state = {
  previous_position = {
    buf = 0,
    win = 0,
    cursor = { 0, 0 },
  },
  previous_position_dir = "",
  buffer_state_counter = 0,
}

local defaults = {
  notes_dir = "$HOME/notes.nvim",
  todo_file = "todo.md",
  file_explorer = "",
}

---@class Notes.Options
---@field notes_dir string: The directory where the notes are stored
---@field todo_file string: The file name for the todo list
---@field file_explorer string: The file explorer to open

---@type Notes.Options
local options = {
  notes_dir = "",
  todo_file = "",
  file_explorer = "",
}

---@param opts Notes.Options
M.setup = function(opts)
  options = vim.tbl_deep_extend("force", defaults, opts or {})
end

local function open_with_oil(path)
  local oil = require("oil")
  oil.open(path)
  vim.wait(1000, function()
    return oil.get_cursor_entry() ~= nil
  end)
  if oil.get_cursor_entry() then
    oil.open_preview()
  end
end

local function save_position()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local is_oil_buffer = vim.bo[buf].filetype == "oil"

  if is_oil_buffer then
    local oil = require("oil")
    local oil_dir = oil.get_current_dir()
    local cursor = vim.api.nvim_win_get_cursor(win)
    return {
      buf = buf,
      win = win,
      cursor = cursor,
      oil_dir = oil_dir,
      is_oil = true,
    }
  end

  return {
    buf = buf,
    win = win,
    cursor = vim.api.nvim_win_get_cursor(win),
    is_oil = false,
  }
end

M._save_position = save_position

local function return_to_position(previous_position)
  if previous_position.is_oil then
    local oil = require("oil")
    if previous_position.oil_dir then
      oil.open(previous_position.oil_dir)
      vim.defer_fn(function()
        vim.api.nvim_win_set_cursor(0, previous_position.cursor)
      end, 100)
    else
      print("No oil directory saved.")
    end
    return
  end

  vim.api.nvim_set_current_buf(previous_position.buf)
  vim.api.nvim_set_current_win(previous_position.win)
  vim.api.nvim_win_set_cursor(previous_position.win, previous_position.cursor)
end

local function process_buffer_state()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" or buf_name == nil then
    state.previous_position = nil
    state.previous_position_dir = vim.fn.getcwd()
  else
    state.previous_position = save_position()
    state.previous_position_dir = nil
  end
end

local function open_with_file_explorer(path)
  if options.file_explorer == "oil" then
    open_with_oil(path)
  else
    vim.cmd("Ex " .. path)
  end
end

local function append_date()
  local today = os.date("%Y-%m-%d")
  local day_of_week = os.date("%A ")
  local search_result = vim.fn.search(today, "nw")
  if search_result == 0 then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", "### " .. day_of_week .. today })
    vim.api.nvim_command("write")
  end
end

function M.OpenNotes()
  if state.buffer_state_counter == 0 then
    process_buffer_state()
    state.buffer_state_counter = state.buffer_state_counter + 1
  end
  local notes_dir = vim.fn.expand(options.notes_dir)
  open_with_file_explorer(notes_dir)
end

function M.OpenTodo()
  if state.buffer_state_counter == 0 then
    process_buffer_state()

    state.buffer_state_counter = state.buffer_state_counter + 1
  end
  local todo_dir = vim.fn.expand(options.notes_dir)
  local todo_path = todo_dir .. "/" .. options.todo_file
  vim.api.nvim_command("edit " .. todo_path)
  -- append_title(options.todo_file)
  append_date()
end

function M.CloseNotes()
  state.buffer_state_counter = 0
  if state.previous_position then
    return_to_position(state.previous_position)
    state.previous_position = {}
  elseif state.previous_position_dir then
    vim.cmd("cd " .. state.previous_position_dir)
    open_with_file_explorer(state.previous_position_dir)
    state.previous_position_dir = ""
  end
end

function M.SearchNotes()
  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    telescope.find_files({ cwd = vim.fn.expand(options.notes_dir) })
  else
    print("Telescope is not installed!")
  end
end

vim.api.nvim_create_autocmd("BufRead", {
  pattern = options.todo_file,
  callback = function()
    vim.keymap.set("n", "<Leader>na", ":normal! o- [ ] <Esc>", { desc = "[N]otes [A]dd Checklist" })
  end,
})

-- Subcommands setup
---@class NotesCmdSubcommand
---@field impl fun(args: string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback

---@type table<string, NotesCmdSubcommand>
M.subcommand_tbl = {
  open = {
    impl = function(args, opts)
      require("notes").OpenNotes()
    end,
  },
  close = {
    impl = function(args, opts)
      require("notes").CloseNotes()
    end,
  },
  todo = {
    impl = function(args, opts)
      require("notes").OpenTodo()
    end,
  },
  search = {
    impl = function(args, opts)
      require("notes").SearchNotes()
    end,
  },
}

-- Helper Functions
---@param opts table :h lua-guide-commands-create
function M.notes_cmd(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = M.subcommand_tbl[subcommand_key]

  if not subcommand then
    vim.notify("Notes: Unknown subcommand: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end

  subcommand.impl(args, opts)
end

-- Set up commands
vim.api.nvim_create_user_command("Notes", M.notes_cmd, {
  nargs = "+", -- Allow arguments for subcommands
  desc = "Plugin commands for Notes", -- Description of your plugin command
  complete = function(arg_lead, cmdline, _)
    local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Notes[!]*%s(%S+)%s(.*)$")

    -- Subcommand completions
    if subcmd_key and subcmd_arg_lead and M.subcommand_tbl[subcmd_key] and M.subcommand_tbl[subcmd_key].complete then
      return M.subcommand_tbl[subcmd_key].complete(subcmd_arg_lead)
    end

    -- Subcommand suggestions
    if cmdline:match("^['<,'>]*Notes[!]*%s+%w*$") then
      local subcommand_keys = vim.tbl_keys(M.subcommand_tbl)
      return vim
        .iter(subcommand_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
    end
  end,
  bang = true, -- If you want to support `!` modifiers
})

-- Keymap KEYMAP --
vim.keymap.set("n", "<Plug>(OpenNotes)", function()
  M.OpenNotes()
end, { noremap = true })
vim.keymap.set("n", "<Plug>(CloseNotes)", function()
  M.CloseNotes()
end, { noremap = true })
vim.keymap.set("n", "<Plug>(OpenTodo)", function()
  M.OpenTodo()
end, { noremap = true })
vim.keymap.set("n", "<Plug>(SearchNotes)", function()
  M.SearchNotes()
end, { noremap = true })
return M
