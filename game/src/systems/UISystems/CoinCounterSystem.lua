local System = require("src.core.System")
local CoinCounter = require("src.ui.CoinCounter")
local GameState = require("src.core.GameState")
local EventBus = require("src.utils.EventBus")

---@class CoinCounterSystem : System
local CoinCounterSystem = System:extend("CoinCounterSystem", {})

---Create a new CoinCounterSystem
---@return CoinCounterSystem
function CoinCounterSystem.new()
    ---@class CoinCounterSystem
    local self = System.new({})
    setmetatable(self, CoinCounterSystem)

    -- Create the coin counter UI element anchored bottom-left
    self.coinCounter = CoinCounter.new(32, 32)
    do
        local h = self.coinCounter.font and self.coinCounter.font:getHeight() or 36
        local elemHeight = math.max(h, 36)
        local screenH, screenW = love.graphics.getHeight(), love.graphics.getWidth()
        self.coinCounter.x = screenW / 2 + 332
        self.coinCounter.y = screenH - elemHeight - 72
    end

    -- Listen for coin pickup events to update UI immediately
    EventBus.subscribe("coinPickedUp", function(payload)
        local total = payload and payload.total or GameState.getTotalCoins()
        local session = GameState.getCoinsThisSession()
        self.coinCounter:updateCoins(total, session)
    end)

    return self
end

---Update the coin counter system
---@param dt number Delta time
function CoinCounterSystem:update(dt)
    -- Update the coin counter with current values from GameState
    local totalCoins = GameState.getTotalCoins()
    local sessionCoins = GameState.getCoinsThisSession()

    self.coinCounter:updateCoins(totalCoins, sessionCoins)
end

---Draw the coin counter
function CoinCounterSystem:draw()
    self.coinCounter:draw()
end

return CoinCounterSystem
