-- Import System base class
local System = require("src.core.System")

---@class StateMachineSystem : System
---System that updates all StateMachine components
local StateMachineSystem = setmetatable({}, {__index = System})
StateMachineSystem.__index = StateMachineSystem

---Create a new StateMachineSystem
---@return StateMachineSystem|System
function StateMachineSystem.new()
    local self = System.new({"StateMachine"})
    setmetatable(self, StateMachineSystem)
    return self
end

---Update all entities with StateMachine components
---@param dt number Delta time
function StateMachineSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local stateMachine = entity:getComponent("StateMachine")
        if stateMachine then
            stateMachine:update(dt, entity)
        end
    end
end

return StateMachineSystem
