---@class ExperienceHUD
local ExperienceHUD = {}
local HUDLayout = require("src.ui.utils.HUDLayout")

---Calculate experience needed for next level
---@param currentLevel number Current player level
---@return number Experience needed to reach next level
local function getExperienceNeededForNextLevel(currentLevel)
    -- Simple linear formula: each level requires more experience
    -- Base: 100 exp for level 1->2, then +50 per level
    return 100 + ((currentLevel - 1) * 50)
end

---Draw the experience bar in screen space (above action bar and unitframe)
---@param world World
function ExperienceHUD.draw(world)
    if not world then
        return
    end

    local player = world.getPlayer and world:getPlayer() or nil
    local playerLevel = nil
    local currentExp = 0
    local expNeeded = 100
    local expPct = 0.0

    if player then
        playerLevel = player:getComponent("PlayerLevel")
        if playerLevel then
            local level = playerLevel:getLevel()
            currentExp = playerLevel:getExperience()
            expNeeded = getExperienceNeededForNextLevel(level)
            
            -- Calculate experience percentage (0-1)
            if expNeeded > 0 then
                expPct = math.max(0, math.min(1, currentExp / expNeeded))
            else
                expPct = 1.0 -- Max level reached
            end
        end
    end

    love.graphics.push()
    love.graphics.origin()

    local sw, sh = love.graphics.getDimensions()

    -- Get action bar position
    local actionBarX, actionBarY = HUDLayout.getActionBarPosition(sw, sh)

    -- Get unitframe positions to calculate width
    local unitframePos = HUDLayout.getUnitframePositions(sw, sh, actionBarX, actionBarY)

    -- Get experience bar position
    local expBarX, expBarY, expBarWidth = HUDLayout.getExperienceBarPosition(sw, sh, actionBarX, actionBarY, unitframePos.unitframeWidth)

    local r, g, b, a = love.graphics.getColor()
    local prevLineWidth = love.graphics.getLineWidth()

    -- Draw experience bar background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
    love.graphics.rectangle("fill", expBarX, expBarY, expBarWidth, HUDLayout.EXP_BAR_HEIGHT, 3, 3)

    -- Draw experience fill (purple/violet color typical for XP bars)
    if expPct > 0 then
        love.graphics.setColor(0.6, 0.3, 0.8, 1.0) -- Purple/violet for experience
        love.graphics.rectangle("fill", expBarX, expBarY, expBarWidth * expPct, HUDLayout.EXP_BAR_HEIGHT, 3, 3)
    end

    -- Draw experience bar border
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", expBarX, expBarY, expBarWidth, HUDLayout.EXP_BAR_HEIGHT, 3, 3)

    love.graphics.setLineWidth(prevLineWidth)

    -- Restore color and stack
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return ExperienceHUD

