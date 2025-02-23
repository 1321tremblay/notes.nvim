local previous_position = {}

local M = {}

M.config = {
  notes_dir = "$HOME/notes.nvim",
}

function M.setup(opts)
  vim.api.nvim_out_write("Default config: " .. vim.inspect(M.config) .. "\n")
  vim.api.nvim_out_write("User opts: " .. vim.inspect(opts) .. "\n")

  M.config = vim.tbl_extend("force", M.config, opts or {})

  vim.api.nvim_out_write("Final config: " .. vim.inspect(M.config) .. "\n")
end

function M.OpenNotes()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()
  local current_cursor = vim.api.nvim_win_get_cursor(current_win)

  previous_position = {
    buf = current_buf,
    win = current_win,
    cursor = current_cursor,
  }

  local oil_ok, oil = pcall(require, "oil")
  if M.config.notes_dir then
    local notes_dir = vim.fn.expand(M.config.notes_dir)
    if oil_ok then
      oil.open(notes_dir)
    else
      vim.cmd("Ex " .. notes_dir)
      return
    end
  end
end

function M.CloseNotes()
  local current_working_dir = vim.fn.getcwd()

  if not previous_position.buf then
    print("No previous position saved!")
    local oil_ok, oil = pcall(require, "oil")
    if oil_ok then
      oil.open(current_working_dir)
    else
      vim.cmd("Ex " .. current_working_dir)
    end

    return
  end

  vim.api.nvim_set_current_buf(previous_position.buf)
  vim.api.nvim_set_current_win(previous_position.win)
  vim.api.nvim_win_set_cursor(previous_position.win, previous_position.cursor)

  previous_position = {}
end

function M.SearchNotes()
  local telescope_ok, telescope = pcall(require, "telescope.builtin")
  if telescope_ok then
    telescope.find_files({ cwd = "$HOME/personal/notes" })
  else
    print("Telescope is not installed!")
  end
end

vim.api.nvim_create_user_command("OpenNotes", "lua require('notes').OpenNotes()", {})
vim.api.nvim_create_user_command("CloseNotes", "lua require('notes').CloseNotes()", {})

vim.api.nvim_create_user_command("SearchNotes", "lua require('notes').SearchNotes()", {})

return M
