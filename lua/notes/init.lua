print("Hello from notes")
local M = {}

local state = {
  previous_position = {
    buf = 0,
    win = 0,
    cursor = { 0, 0 },
  },
  previous_position_dir = "",
  buffer_state_counter = 0,
  note_close_counter = 0,
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

-- Get the current buffer and its filetype
local function get_current_buf()
  local buffer = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[buffer].filetype
  return buffer, filetype
end

-- Get the current window
local function get_current_win()
  return vim.api.nvim_get_current_win()
end

-- Get the cursor position in a window
local function get_cursor_position(window)
  return vim.api.nvim_win_get_cursor(window)
end

-- Save the current position (handles Oil and regular buffers)
local function save_current_position()
  local buf, filetype = get_current_buf()
  local win = get_current_win()
  local cursor = get_cursor_position(win)

  if filetype == "oil" then
    local oil = require("oil")
    return {
      buf = buf,
      win = win,
      cursor = cursor,
      oil_dir = oil.get_current_dir(),
      is_oil = true,
    }
  end

  return {
    buf = buf,
    win = win,
    cursor = cursor,
    is_oil = false,
  }
end

-- Update previous position state before opening Notes
local function update_previous_position()
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == "" or buf_name == nil then
    state.previous_position = nil
    state.previous_position_dir = vim.fn.getcwd()
  else
    state.previous_position = save_current_position()
    state.previous_position_dir = nil
  end
end

-- Restore the previous position after closing Notes
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

-- Open Oil if configured as the file explorer
local function open_oil(path)
  local oil = require("oil")
  oil.open(path)
  vim.wait(1000, function()
    return oil.get_cursor_entry() ~= nil
  end)
  if oil.get_cursor_entry() then
    oil.open_preview()
  end
end

-- Open the file explorer (Oil or default)
local function open_explorer(path)
  if options.file_explorer == "oil" then
    open_oil(path)
  else
    vim.cmd("Ex " .. path)
  end
end

-- Append today's date if not already present
local function append_date()
  local today = os.date("%Y-%m-%d")
  local day_of_week = os.date("%A ")
  local search_result = vim.fn.search(today, "nw")
  if search_result == 0 then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "", "### " .. day_of_week .. today })
    vim.api.nvim_command("write")
  end
end

-- Open Notes directory
function M.OpenNotes()
  if state.buffer_state_counter == 0 then
    update_previous_position()
    state.buffer_state_counter = state.buffer_state_counter + 1
  end
  open_explorer(vim.fn.expand(options.notes_dir))
end

-- Open the Todo file and append date if necessary
function M.OpenTodo()
  if state.buffer_state_counter == 0 then
    update_previous_position()
    state.buffer_state_counter = state.buffer_state_counter + 1
  end
  vim.api.nvim_command("edit " .. vim.fn.expand(options.notes_dir) .. "/" .. options.todo_file)
  append_date()
end

-- Close Notes and restore the previous position
function M.CloseNotes()
  state.buffer_state_counter = 0
  if state.previous_position then
    return_to_position(state.previous_position)
    state.previous_position = {}
  elseif state.previous_position_dir then
    vim.cmd("cd " .. state.previous_position_dir)
    open_explorer(state.previous_position_dir)
    state.previous_position_dir = ""
  end
end

-- Search Notes using Telescope
function M.SearchNotes()
  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    telescope.find_files({ cwd = vim.fn.expand(options.notes_dir) })
  else
    print("Telescope is not installed!")
  end
end

-- Auto-command to add a checklist item when opening the Todo file
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
    impl = function()
      M.OpenNotes()
    end,
  },
  close = {
    impl = function()
      M.CloseNotes()
    end,
  },
  todo = {
    impl = function()
      M.OpenTodo()
    end,
  },
  search = {
    impl = function()
      M.SearchNotes()
    end,
  },
}

-- Command handler
---@param opts table :h lua-guide-commands-create
function M.notes_cmd(opts)
  local subcommand = M.subcommand_tbl[opts.fargs[1]]
  if not subcommand then
    vim.notify("Notes: Unknown subcommand: " .. opts.fargs[1], vim.log.levels.ERROR)
    return
  end
  subcommand.impl()
end

-- Register the "Notes" command
vim.api.nvim_create_user_command("Notes", M.notes_cmd, {
  nargs = "+",
  desc = "Plugin commands for Notes",
  complete = function(arg_lead)
    return vim.tbl_filter(function(key)
      return key:find(arg_lead)
    end, vim.tbl_keys(M.subcommand_tbl))
  end,
  bang = true,
})

-- Keymap bindings
vim.keymap.set("n", "<Plug>(OpenNotes)", M.OpenNotes, { noremap = true })
vim.keymap.set("n", "<Plug>(CloseNotes)", M.CloseNotes, { noremap = true })
vim.keymap.set("n", "<Plug>(OpenTodo)", M.OpenTodo, { noremap = true })
vim.keymap.set("n", "<Plug>(SearchNotes)", M.SearchNotes, { noremap = true })

return M
