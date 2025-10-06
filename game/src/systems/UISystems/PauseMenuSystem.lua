local System = require("src.core.System")
local PauseMenu = require("src.ui.PauseMenu")

---@class PauseMenuSystem : System
local PauseMenuSystem = System:extend("PauseMenuSystem", {})

function PauseMenuSystem.new()
    ---@class PauseMenuSystem
    local self = System.new({})
    setmetatable(self, PauseMenuSystem)
    self.isWorldSpace = false -- This UI system draws in screen space
    self.widget = PauseMenu.new()
    return self
end

function PauseMenuSystem:update(dt, gameState)
    -- Update widget visibility based on game pause state
    if self.widget then
        local gameController = require("src.core.GameController")
        self.widget.visible = gameController.paused
        self._wasPaused = gameController.paused
    end
end

function PauseMenuSystem:draw()
    if self.widget and self.widget.draw then
        self.widget:draw()
    end
end

function PauseMenuSystem:handleMouseClick(x, y, button)
    if self.widget and self.widget.handleMouseClick then
        -- @diagnostic disable-next-line: undefined-field
        return self.widget:handleMouseClick(x, y, button)
    end
    return false
end

return PauseMenuSystem
