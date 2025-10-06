local System = require("src.core.System")
local GameOver = require("src.ui.GameOver")

---@class GameOverSystem : System
local GameOverSystem = System:extend("GameOverSystem", {})

function GameOverSystem.new()
    ---@class GameOverSystem
    local self = System.new({})
    setmetatable(self, GameOverSystem)
    self.isWorldSpace = false
    self.widget = GameOver.new()
    return self
end

function GameOverSystem:update(dt, gameState)
    local controller = require("src.core.GameController")
    if self.widget then
        self.widget.visible = controller.gameOver == true
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

return GameOverSystem


