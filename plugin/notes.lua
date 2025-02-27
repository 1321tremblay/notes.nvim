require("notes")

vim.api.nvim_create_user_command("ReloadNotes", function()
  -- Unload the notes module to force a reload
  package.loaded["notes"] = nil

  -- Reload the notes module
  require("notes")
  vim.notify("Notes plugin reloaded successfully!", vim.log.levels.INFO)
end, {
  desc = "Reload the Notes plugin", -- Description for the command
})
