local notes = require("notes")

describe("get_cursor_position", function()
  it("should return a table with two numbers: line and column", function()
    -- Assume window 0 is the current window
    local position = notes._get_cursor_position(0)

    -- Check that position is a table
    assert.is_table(position)

    -- Check that the table has exactly two elements
    assert.is_equal(#position, 2)

    -- Check that both elements are numbers (line and column)
    assert.is_number(position[1]) -- line
    assert.is_number(position[2]) -- column
  end)

  it("should return the cursor position for the given window", function()
    -- Test with window 0
    local position = notes._get_cursor_position(0)
    assert.are.same(position, { 1, 0 })
  end)
end)
