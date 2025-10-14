local System = require("src.core.System")
local PauseMenu = require("src.ui.PauseMenu")

---@class PauseMenuSystem : System
local PauseMenuSystem = System:extend("PauseMenuSystem", {})

function PauseMenuSystem.new()
    ---@class PauseMenuSystem
    local self = System.new({})
    setmetatable(self, PauseMenuSystem)
    self.isWorldSpace = false -- This UI system draws in screen space
    self.drawOrder = 1000 -- Draw on top of other UI elements
    self.widget = PauseMenu.new()
    return self
end

function PauseMenuSystem:update(dt, gameState)
    -- Update widget visibility based on game pause state
    if self.widget then
        local gameController = require("src.core.GameController")
        self.widget.visible = gameController.paused and not gameController.gameOver
        self._wasPaused = gameController.paused

        -- Update widget (hover states, etc.)
        if self.widget.update then
            self.widget:update(dt, gameState)
        end
    end
end

function PauseMenuSystem:draw()
    if self.widget and self.widget.draw then
        self.widget:draw()
    end
end

function PauseMenuSystem:handleMouseClick(x, y, button)
    -- If pause menu is visible, consume all clicks
    local gameController = require("src.core.GameController")
    if gameController.paused and not gameController.gameOver then
        if self.widget and self.widget.handleMouseClick then
            -- @diagnostic disable-next-line: undefined-field
            self.widget:handleMouseClick(x, y, button)
        end
        return true -- Consume the click event
    end
    return false
end

function PauseMenuSystem:handleMousePressed(x, y, button)
    -- If pause menu is visible, consume all clicks to prevent interaction with game elements below
    local gameController = require("src.core.GameController")
    if gameController.paused and not gameController.gameOver then
        if self.widget and self.widget.handleMousePressed then
            self.widget:handleMousePressed(x, y, button)
        end
        return true -- Consume the click event
    end
    return false
end

function PauseMenuSystem:handleMouseReleased(x, y, button)
    -- If pause menu is visible, consume all clicks
    local gameController = require("src.core.GameController")
    if gameController.paused and not gameController.gameOver then
        if self.widget and self.widget.handleMouseReleased then
            self.widget:handleMouseReleased(x, y, button)
        end
        return true -- Consume the click event
    end
    return false
end

function PauseMenuSystem:handleKeyPress(key)
    if self.widget and self.widget.handleKeyPress then
        return self.widget:handleKeyPress(key)
    end
    return false
end

return PauseMenuSystem
