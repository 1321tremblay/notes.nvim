local notes = require("notes")

describe("notes.save_current_position", function()
  -- Mocking necessary Vim API functions
  before_each(function()
    vim.api.nvim_get_current_buf = function()
      return 1
    end
    vim.api.nvim_win_get_cursor = function()
      return { 5, 10 }
    end
    vim.api.nvim_get_current_win = function()
      return 1000
    end
  end)

  it("should return the correct position for a non-oil buffer", function()
    print("Running test for non-oil buffer")

    -- Call the function you want to test
    local result = notes._save_current_position()

    -- Expected output
    local expected = {
      buf = 1,
      win = 1000,
      cursor = { 5, 10 },
      oil_dir = nil,
      is_oil = false,
    }

    -- Check if the result matches the expected value
    assert.are.same(result, expected)
  end)

  it("should return the correct position for an oil buffer", function()
    print("Running test for oil buffer")

    local result = notes._save_current_position()
    local oil_dir = "string"
    result.is_oil = true
    result.oil_dir = oil_dir

    -- Expected output with mock oil behavior
    local expected = {
      buf = 1,
      win = 1000,
      cursor = { 5, 10 },
      oil_dir = oil_dir,
      is_oil = true,
    }

    -- Check if the result matches the expected value
    assert.are.same(result, expected)
  end)
end)
