local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

---@class CoinCounter : UIElement
---@field x number X position
---@field y number Y position
---@field totalCoins number Current total coin count
---@field coinsThisSession number Coins collected this session
---@field font love.Font Font for rendering text
---@field coinIcon string Icon/symbol to display next to coin count
local CoinCounter = {}
CoinCounter.__index = CoinCounter

---Create a new CoinCounter UI element
---@param x number X position
---@param y number Y position
---@return CoinCounter
function CoinCounter.new(x, y)
    local self = UIElement.new()
    setmetatable(self, CoinCounter)

    self.x = x
    self.y = y
    self.totalCoins = 0
    self.coinsThisSession = 0
    -- Use the same font size as HealthBarHUD for consistency
    self.font = fonts.getUIFont(36) -- Same as HealthBarHUD damage numbers

    -- Set up coin sprite properties (using iffy system)
    self.coinSpriteSheet = "coin"
    self.coinFrame = 1 -- First frame of coin animation
    self.coinSpriteWidth = 36 -- Larger size for better visibility
    self.coinSpriteHeight = 36

    return self
end

---Update the coin counter with current values
---@param totalCoins number Total coins
---@param sessionCoins number Coins this session
function CoinCounter:updateCoins(totalCoins, sessionCoins)
    self.totalCoins = totalCoins or 0
    self.coinsThisSession = sessionCoins or 0
end

---Draw the coin counter
function CoinCounter:draw()
    if not self.visible then return end

    -- Save current graphics state
    local r, g, b, a = love.graphics.getColor()
    local prevFont = love.graphics.getFont()

    -- Reset coordinate system for screen-space rendering
    love.graphics.push()
    love.graphics.origin()

    -- Set up colors
    local textColor = {1, 1, 1, 1} -- White text
    local shadowColor = {0, 0, 0, 0.8} -- Black shadow for readability
    local totalText = string.format("%d", self.totalCoins)

    -- Set font
    if self.font then
        love.graphics.setFont(self.font)
    end

    -- Draw coin sprite using iffy
    local iffy = require("lib.iffy")
    if iffy.spritesheets[self.coinSpriteSheet] and iffy.spritesheets[self.coinSpriteSheet][self.coinFrame] then
        love.graphics.setColor(1, 1, 1, 1) -- White color for sprite
        local scale = self.coinSpriteWidth / 16 -- Scale from original 16px to desired size
        iffy.draw(
            self.coinSpriteSheet,
            self.coinFrame,
            self.x,
            self.y + (self.font:getHeight() - self.coinSpriteHeight) / 2, -- Center vertically with text
            0, -- No rotation
            scale, -- Scale X
            scale  -- Scale Y
        )
    end

    -- Calculate text position (to the right of the coin sprite)
    local textX = self.x + self.coinSpriteWidth + 8 -- 8px spacing between sprite and text

    -- Draw total coins with shadow
    love.graphics.setColor(shadowColor)
    love.graphics.print(totalText, textX + 1, self.y + 1)
    love.graphics.setColor(textColor)
    love.graphics.print(totalText, textX, self.y)

    -- Restore graphics state
    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return CoinCounter
