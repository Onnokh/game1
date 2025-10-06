local System = require("src.core.System")
local SiegeCounter = require("src.ui.SiegeCounter")

---@class SiegeCounterSystem : System
---@field isWorldSpace boolean
---@field widget any
local SiegeCounterSystem = System:extend("SiegeCounterSystem", {})

function SiegeCounterSystem.new()
    local self = System.new({})
    setmetatable(self, SiegeCounterSystem)
    self.isWorldSpace = false
    self.widget = SiegeCounter.new()
    return self
end

function SiegeCounterSystem:draw()
    if self.widget and self.widget.draw then
        self.widget:draw()
    end
end

return SiegeCounterSystem



