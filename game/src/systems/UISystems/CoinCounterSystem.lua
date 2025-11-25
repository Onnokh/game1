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
    local self = System.new()
    setmetatable(self, CoinCounterSystem)

    -- Create the coin counter UI element anchored top-left (below auto-aim text)
    self.coinCounter = CoinCounter.new(32, 32)
    do
        local h = self.coinCounter.font and self.coinCounter.font:getHeight() or 36
        local elemHeight = math.max(h, 36)
        local screenH, screenW = love.graphics.getHeight(), love.graphics.getWidth()
        local TOP_MARGIN = 32
        local AUTO_AIM_TEXT_HEIGHT = 18  -- Height of auto-aim text
        local SPACING = 8  -- Spacing between auto-aim text and coin counter
        self.coinCounter.x = 32  -- Left margin
        self.coinCounter.y = TOP_MARGIN + AUTO_AIM_TEXT_HEIGHT + SPACING  -- Below auto-aim text
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
