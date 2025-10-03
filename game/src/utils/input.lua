---@class InputHelpers
---Common input utility functions
local InputHelpers = {}

---Check if any movement input is currently pressed
---@param input table Input state table with left, right, up, down fields
---@return boolean True if any movement key is pressed
function InputHelpers.hasMovementInput(input)
    return input.left or input.right or input.up or input.down
end

---Check if running input is pressed (shift key)
---@param input table Input state table with shift field
---@return boolean True if shift is pressed
function InputHelpers.isRunningInput(input)
    return input.shift
end

---Check if action input is pressed (space, enter)
---@param input table Input state table with action field
---@return boolean True if action key is pressed
function InputHelpers.isActionInput(input)
    return input.action
end

---Check if cancel input is pressed (escape)
---@param input table Input state table with cancel field
---@return boolean True if cancel key is pressed
function InputHelpers.isCancelInput(input)
    return input.cancel
end

return InputHelpers
