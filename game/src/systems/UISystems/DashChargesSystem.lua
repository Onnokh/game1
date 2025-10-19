local System = require("src.core.System")
local DashChargesHUD = require("src.ui.DashChargesHUD")

---@class DashChargesSystem : System
---UI System that draws the dash charges HUD
local DashChargesSystem = System:extend("DashChargesSystem", {})

---Create a new DashChargesSystem
---@return DashChargesSystem
function DashChargesSystem.new()
    ---@class DashChargesSystem
    local self = System.new()
    setmetatable(self, DashChargesSystem)
    self.isWorldSpace = false -- This UI system draws in screen space

    return self
end

---Draw the dash charges HUD
function DashChargesSystem:draw()
    if self.world then
        print("Dash UI Debug - DashChargesSystem draw() called")
        DashChargesHUD.draw(self.world)
    else
        print("Dash UI Debug - No world in DashChargesSystem")
    end
end

return DashChargesSystem
