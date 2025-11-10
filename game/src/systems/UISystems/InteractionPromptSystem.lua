local System = require("src.core.System")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local gameState = require("src.core.GameState")

---@class InteractionPromptSystem : System
---@field ecsWorld World
---@field currentPrompt table|nil
local InteractionPromptSystem = System:extend("InteractionPromptSystem", {})

function InteractionPromptSystem.new(ecsWorld)
    ---@class InteractionPromptSystem
    local self = System.new()
    setmetatable(self, InteractionPromptSystem)
    self.ecsWorld = ecsWorld
    self.currentPrompt = nil
    self.isWorldSpace = false -- draw in screen space (convert world to screen manually)

    -- Find and store reference to InteractionSystem
    self.interactionSystem = nil
    if ecsWorld and ecsWorld.systems then
        for _, system in ipairs(ecsWorld.systems) do
            if system.getNearestInteractable and system.getNearestInteractionText and system.isNearInteractable then
                self.interactionSystem = system
                break
            end
        end
    end

    return self
end

function InteractionPromptSystem:update(dt)
    -- Check if we have an InteractionSystem to get the nearest interactable
    if self.interactionSystem then
        local nearestInteractable = self.interactionSystem:getNearestInteractable()
        local interactionText = self.interactionSystem:getNearestInteractionText()
        local isNearInteractable = self.interactionSystem:isNearInteractable()

        if nearestInteractable and isNearInteractable and interactionText then
            -- Update current prompt
            local position = nearestInteractable:getComponent("Position")
            local spriteRenderer = nearestInteractable:getComponent("SpriteRenderer")

            if position then
                local entityWidth = (spriteRenderer and spriteRenderer.width) or 32
                local entityHeight = (spriteRenderer and spriteRenderer.height) or 32

                self.currentPrompt = {
                    text = interactionText,
                    worldX = position.x + entityWidth * 0.5, -- Center horizontally
                    worldY = position.y + entityHeight + 2, -- Just below the entity
                    entity = nearestInteractable
                }
            else
                self.currentPrompt = nil
            end
        else
            self.currentPrompt = nil
        end
    end
end

function InteractionPromptSystem:draw()
    if not self.currentPrompt then
        return
    end

    local r, g, b, a = love.graphics.getColor()

    -- Convert world position to screen coordinates
    local CoordinateUtils = require("src.utils.coordinates")
    local screenX, screenY = CoordinateUtils.worldToScreen(self.currentPrompt.worldX, self.currentPrompt.worldY, gameState.camera)

    -- Use fixed-size font for consistent screen-space text (not affected by camera zoom)
    local font = fonts.getUIFont(18)
    local prevFont = love.graphics.getFont()

    love.graphics.push()
    love.graphics.origin()
    if font then love.graphics.setFont(font) end

    -- Set color for the prompt (bright white with slight glow)
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

    local text = self.currentPrompt.text
    local w = font and font:getWidth(text) or 0
    local h = font and font:getHeight() or 0
    local x = math.floor(screenX - w * 0.5 + 0.5)
    local y = math.floor(screenY - h + 0.5)

    -- Draw outlined text for better visibility
    love.graphics.push()
    love.graphics.translate(x + w * 0.5, y + h * 0.5)

    -- Draw outlined text for better visibility
    local outlinePx = 2
    ui_text.drawOutlinedText(text, -w * 0.5, -h * 0.5, {1.0, 1.0, 1.0, 1.0}, {0, 0, 0, 0.8}, outlinePx)

    love.graphics.pop()
    love.graphics.pop()

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
end

return InteractionPromptSystem
