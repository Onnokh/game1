local System = require("src.core.System")
local GameOver = require("src.ui.GameOver")

---@class GameOverSystem : System
local GameOverSystem = System:extend("GameOverSystem", {})

function GameOverSystem.new()
    ---@class GameOverSystem
    local self = System.new({})
    setmetatable(self, GameOverSystem)
    self.isWorldSpace = false
    self.drawOrder = 1000 -- Draw on top of other UI elements
    self.widget = GameOver.new()
    return self
end

function GameOverSystem:update(dt, gameState)
    local controller = require("src.core.GameController")
    if self.widget then
        self.widget.visible = controller.gameOver == true

        -- Update widget (hover states, etc.)
        if self.widget.update then
            self.widget:update(dt, gameState)
        end
    end
end

function GameOverSystem:draw()
    if self.widget and self.widget.draw then
        self.widget:draw()
    end
end

function GameOverSystem:handleMouseClick(x, y, button)
    if self.widget and self.widget.handleMouseClick then
        return self.widget:handleMouseClick(x, y, button)
    end
    return false
end

function GameOverSystem:handleMousePressed(x, y, button)
    if self.widget and self.widget.handleMousePressed then
        return self.widget:handleMousePressed(x, y, button)
    end
    return false
end

function GameOverSystem:handleMouseReleased(x, y, button)
    if self.widget and self.widget.handleMouseReleased then
        return self.widget:handleMouseReleased(x, y, button)
    end
    return false
end

function GameOverSystem:handleKeyPress(key)
    if self.widget and self.widget.handleKeyPress then
        return self.widget:handleKeyPress(key)
    end
    return false
end

return GameOverSystem


