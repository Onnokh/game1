---@class Component
---@field type string The type of this component
local Component = {}
Component.__index = Component

---Create a new component
---@param componentType string The type of component
---@return Component
function Component.new(componentType)
    local self = setmetatable({}, Component)
    self.type = componentType
    return self
end

return Component
