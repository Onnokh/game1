local System = require("src.core.System")
local GameConstants = require("src.constants")
local EntityUtils = require("src.utils.entities")

---@class OxygenSystem : System
local OxygenSystem = System:extend("OxygenSystem", {"Position", "Oxygen"})

-- Tether attachment points defined as pixel coordinates from sprite's top-left corner
local TETHER_ATTACHMENT_POINTS = {
    Reactor = {
        -- 96x96 sprite
        {x = 21, y = 50},  -- Left center
        {x = 74, y = 50},  -- Right center
        {x = 17, y = 67},  -- Bottom-Left
        {x = 78, y = 67},  -- Bottom-Right
    },
    Player = {
        -- 24x24 sprite
        {x = 12, y = 16},   -- Top center
    }
}

function OxygenSystem:init()
    -- Track tether connection state for snap effect
    self.tetherWasConnected = false
    self.snapTimer = 0
    self.snapDuration = 0.15 -- Duration of snap animation in seconds
    self.snapStartPos = {x = 0, y = 0} -- Where the snap animation starts from
    self.snapEndPos = {x = 0, y = 0} -- Where it snaps to (reactor)

    -- Liquid flow effect
    self.flowPulses = {} -- Array of pulses traveling along the line
    self.flowTimer = 0 -- Time until next pulse
    self.flowInterval = 0.2 -- Time between pulses (seconds)
    self.flowSpeed = .1 -- Speed of pulse travel (0 to 1 per second)
end

---Update all entities with Position and Oxygen components
---@param dt number Delta time
function OxygenSystem:update(dt)
    -- Initialize snap properties if not already initialized
    if not self.snapTimer then
        self.tetherWasConnected = false
        self.snapTimer = 0
        self.snapDuration = 0.15
        self.snapStartPos = {x = 0, y = 0}
        self.snapEndPos = {x = 0, y = 0}
        self.flowPulses = {} -- Array of pulses traveling along the line
        self.flowTimer = 0 -- Time until next pulse
        self.flowInterval = .5 -- Time between pulses (seconds)
        self.flowSpeed = 1.2 -- Speed of pulse travel (0 to 1 per second)
    end

    -- Update snap animation timer
    if self.snapTimer > 0 then
        self.snapTimer = self.snapTimer - dt
        if self.snapTimer < 0 then
            self.snapTimer = 0
        end
    end

    -- Update liquid flow effect (only when tether is connected)
    if self.tetherWasConnected then
        -- Update flow timer and spawn new pulses
        self.flowTimer = self.flowTimer + dt
        if self.flowTimer >= self.flowInterval then
            self.flowTimer = self.flowTimer - self.flowInterval
            table.insert(self.flowPulses, 0) -- Start at position 0 (reactor end)
        end

        -- Update existing pulses
        for i = #self.flowPulses, 1, -1 do
            self.flowPulses[i] = self.flowPulses[i] + dt * self.flowSpeed
            -- Remove pulses that have reached the end
            if self.flowPulses[i] > 1 then
                table.remove(self.flowPulses, i)
            end
        end
    else
        -- Clear pulses when disconnected
        self.flowPulses = {}
        self.flowTimer = 0
    end

    -- Get current phase from GameState
    local GameState = require("src.core.GameState")
    local currentPhase = GameState and GameState.phase

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local oxygen = entity:getComponent("Oxygen")

        if position and oxygen then
            -- Check if entity is in the reactor's safe zone (using entity center)
            local centerX, centerY = EntityUtils.getEntityVisualCenter(entity, position)
            local isInSafeZone = self:isInReactorSafeZone(centerX, centerY)

            if currentPhase == "Siege" then
                -- During Siege: restore oxygen when in safe zone, decay when outside
                if isInSafeZone then
                    oxygen:restore(GameConstants.OXYGEN_RESTORE_RATE * dt)
                else
                    oxygen:reduce(GameConstants.OXYGEN_DECAY_RATE * dt)
                end
            else
                -- During Discovery: only decay oxygen if outside the safe zone
                if not isInSafeZone then
                    oxygen:reduce(GameConstants.OXYGEN_DECAY_RATE * dt)
                end
            end
        end
    end
end

---Check if a position is within the reactor's safe oxygen zone
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if position is in safe zone
function OxygenSystem:isInReactorSafeZone(x, y)
    -- Find the reactor entity in the world
    local reactor = EntityUtils.findReactor(self.world)

    if not reactor then
        -- If no reactor found, assume we're always in danger
        return false
    end

    local reactorPosition = reactor:getComponent("Position")
    if not reactorPosition then
        return false
    end

    -- Calculate distance to reactor's sprite center (not collider center)
    -- The reactor is a 96x96 sprite, so we want the true visual center
    local spriteRenderer = reactor:getComponent("SpriteRenderer")
    local reactorCenterX = reactorPosition.x + (spriteRenderer and spriteRenderer.width or 96) / 2
    local reactorCenterY = reactorPosition.y + (spriteRenderer and spriteRenderer.height or 96) / 2

    local dx = x - reactorCenterX
    local dy = y - reactorCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    return distance <= GameConstants.REACTOR_SAFE_RADIUS
end

---Get attachment points for an entity based on its type
---@param entity Entity The entity to get attachment points for
---@param position table Position component
---@param spriteRenderer table SpriteRenderer component
---@return table Array of attachment points in world coordinates {x, y}
local function getAttachmentPoints(entity, position, spriteRenderer)
    local points = {}

    -- Determine which definition to use
    local definition = nil
    if entity:hasTag("Reactor") then
        definition = TETHER_ATTACHMENT_POINTS.Reactor
    elseif entity:hasTag("Player") then
        definition = TETHER_ATTACHMENT_POINTS.Player
    end

    if definition then
        -- Convert sprite-relative coordinates to world coordinates
        for _, point in ipairs(definition) do
            table.insert(points, {
                x = position.x + point.x,
                y = position.y + point.y
            })
        end
    else
        -- Default: use center of sprite
        local width = spriteRenderer and spriteRenderer.width or 24
        local height = spriteRenderer and spriteRenderer.height or 24
        table.insert(points, {
            x = position.x + width / 2,
            y = position.y + height / 2
        })
    end

    return points
end

---Find the closest point from a list of points to a target position
---@param points table Array of points {x, y}
---@param targetX number Target X position
---@param targetY number Target Y position
---@return number, number The closest point coordinates
local function getClosestPoint(points, targetX, targetY)
    local closestPoint = points[1]
    local minDistance = math.huge

    for _, point in ipairs(points) do
        local dx = point.x - targetX
        local dy = point.y - targetY
        local distance = dx * dx + dy * dy -- Use squared distance for performance

        if distance < minDistance then
            minDistance = distance
            closestPoint = point
        end
    end

    return closestPoint.x, closestPoint.y
end

---Draw method called by World (not used - tether is drawn from RenderSystem)
function OxygenSystem:draw()
    -- Tether is now drawn from RenderSystem between Reactor layers
    -- This method exists to satisfy World:draw() but does nothing
end

---Draw the oxygen tether line between player and reactor
---This is called by RenderSystem when rendering the Reactor entity
function OxygenSystem:drawTether()
    -- Initialize snap properties if not already initialized
    if not self.snapTimer then
        self.tetherWasConnected = false
        self.snapTimer = 0
        self.snapDuration = 0.15
        self.snapStartPos = {x = 0, y = 0}
        self.snapEndPos = {x = 0, y = 0}
    end

    -- Find the reactor entity
    local reactor = EntityUtils.findReactor(self.world)
    if not reactor then
        return
    end

    -- Find the player entity
    local player = nil
    for _, entity in ipairs(self.world.entities) do
        if entity:hasTag("Player") then
            player = entity
            break
        end
    end

    if not player then
        return
    end

    -- Get player position
    local playerPosition = player:getComponent("Position")
    if not playerPosition then
        return
    end

    -- Get reactor position
    local reactorPosition = reactor:getComponent("Position")
    if not reactorPosition then
        return
    end

    -- Get sprite renderers
    local playerSpriteRenderer = player:getComponent("SpriteRenderer")
    local reactorSpriteRenderer = reactor:getComponent("SpriteRenderer")

    -- Calculate centers for distance calculation (use same method as update for consistency)
    local playerCenterX, playerCenterY = EntityUtils.getEntityVisualCenter(player, playerPosition)

    local reactorWidth = reactorSpriteRenderer and reactorSpriteRenderer.width or 96
    local reactorHeight = reactorSpriteRenderer and reactorSpriteRenderer.height or 96
    local reactorCenterX = reactorPosition.x + reactorWidth / 2
    local reactorCenterY = reactorPosition.y + reactorHeight / 2

    -- Calculate distance between player and reactor (for safe zone check)
    local dx = playerCenterX - reactorCenterX
    local dy = playerCenterY - reactorCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    -- Get all attachment points for both entities
    local reactorPoints = getAttachmentPoints(reactor, reactorPosition, reactorSpriteRenderer)
    local playerPoints = getAttachmentPoints(player, playerPosition, playerSpriteRenderer)

    -- Find closest reactor point to player center
    local reactorAttachX, reactorAttachY = getClosestPoint(reactorPoints, playerCenterX, playerCenterY)

    -- Find closest player point to that reactor attachment point
    local playerAttachX, playerAttachY = getClosestPoint(playerPoints, reactorAttachX, reactorAttachY)

    -- Get the safe zone radius from constants
    local safeRadius = GameConstants.REACTOR_SAFE_RADIUS

    local isConnected = distance <= safeRadius

    -- Check if we just disconnected (trigger snap animation)
    if self.tetherWasConnected and not isConnected then
        -- Start snap animation
        self.snapTimer = self.snapDuration
        self.snapStartPos = {x = playerAttachX, y = playerAttachY}
        self.snapEndPos = {x = reactorAttachX, y = reactorAttachY}
    end

    -- Update connection state for next frame
    self.tetherWasConnected = isConnected

    -- Draw the tether if player is within safe radius
    if isConnected then
        -- Calculate opacity based on distance (fade out as player moves away)
        local opacity = 1.0 - (distance / safeRadius)
        opacity = math.max(0.3, opacity) -- Keep minimum visibility

        -- Calculate sag amount - more sag when closer (more slack), less when farther (more tension)
        -- Maximum sag when very close, minimal sag when at the edge of safe radius
        local tensionRatio = distance / safeRadius -- 0 = very close, 1 = at edge
        local maxSag = 30 -- maximum pixels the line can sag
        local sagAmount = maxSag * (1 - tensionRatio) -- More sag when closer

        -- Calculate perpendicular direction for the sag (downward in world space)
        -- We'll make it sag downward (positive Y direction)
        local midX = (reactorAttachX + playerAttachX) / 2
        local midY = (reactorAttachY + playerAttachY) / 2

        -- Add sag to the midpoint (downward)
        local sagMidX = midX
        local sagMidY = midY + sagAmount

        -- Create a smooth curve using multiple segments
        local segments = 12 -- Number of segments for smooth curve
        local points = {}
        local shadowPoints = {}

        -- Shadow offset (down and slightly to the right for realistic lighting)
        local shadowOffsetX = 3
        local shadowOffsetY = 8

        for i = 0, segments do
            local t = i / segments
            -- Quadratic Bezier curve: B(t) = (1-t)²P0 + 2(1-t)tP1 + t²P2
            local x = (1 - t) * (1 - t) * reactorAttachX +
                      2 * (1 - t) * t * sagMidX +
                      t * t * playerAttachX
            local y = (1 - t) * (1 - t) * reactorAttachY +
                      2 * (1 - t) * t * sagMidY +
                      t * t * playerAttachY

            -- Main line points
            table.insert(points, x)
            table.insert(points, y)

            -- Shadow points (offset)
            table.insert(shadowPoints, x + shadowOffsetX)
            table.insert(shadowPoints, y + shadowOffsetY)
        end

        -- Draw the ground shadow first (so it appears behind the line)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 0, 0, opacity * 0.8) -- Dark shadow
        love.graphics.line(shadowPoints)

        -- Draw the elastic tether line on top
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.8, 1.0, 1.0, 0.9) -- Cyan/light blue matching safe zone
        love.graphics.line(points)

        -- Draw liquid flow pulses as ovals
        for _, pulsePos in ipairs(self.flowPulses) do
            -- Calculate position along the Bezier curve
            local t = pulsePos
            local pulseX = (1 - t) * (1 - t) * reactorAttachX +
                          2 * (1 - t) * t * sagMidX +
                          t * t * playerAttachX
            local pulseY = (1 - t) * (1 - t) * reactorAttachY +
                          2 * (1 - t) * t * sagMidY +
                          t * t * playerAttachY

            -- Calculate the direction/angle of the line at this point for oval orientation
            -- Get tangent by differentiating the Bezier curve
            local epsilon = 0.001
            local t_next = math.min(1, t + epsilon)
            local nextX = (1 - t_next) * (1 - t_next) * reactorAttachX +
                         2 * (1 - t_next) * t_next * sagMidX +
                         t_next * t_next * playerAttachX
            local nextY = (1 - t_next) * (1 - t_next) * reactorAttachY +
                         2 * (1 - t_next) * t_next * sagMidY +
                         t_next * t_next * playerAttachY

            -- Calculate angle of the line at this point
            local angle = math.atan2(nextY - pulseY, nextX - pulseX)

            -- Draw oval (ellipse) aligned with the curve direction
            love.graphics.push()
            love.graphics.translate(pulseX, pulseY)
            love.graphics.rotate(angle)

            -- Draw the oval pulse (elongated along the line direction)
            love.graphics.setColor(0.8, 1.0, 1.0, 0.9) -- Bright white for the liquid
            love.graphics.ellipse("fill", 0, 0, 6, 2) -- radiusX=8, radiusY=4 for oval shape

            love.graphics.pop()
        end

        -- Reset graphics state
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
    elseif self.snapTimer > 0 then
        -- Draw snap animation - line retracting back to reactor
        local progress = 1.0 - (self.snapTimer / self.snapDuration) -- 0 to 1

        -- Ease out cubic for a snappy retraction
        local easeProgress = 1 - math.pow(1 - progress, 3)

        -- Interpolate from snap start position back to reactor
        local currentX = self.snapStartPos.x + (self.snapEndPos.x - self.snapStartPos.x) * easeProgress
        local currentY = self.snapStartPos.y + (self.snapEndPos.y - self.snapStartPos.y) * easeProgress

        -- Calculate a stretched tether (less sag, more tension during snap)
        local midX = (self.snapEndPos.x + currentX) / 2
        local midY = (self.snapEndPos.y + currentY) / 2

        -- Very minimal sag during snap (taut line)
        local snapSag = 5 * (1 - progress) -- Sag reduces as it snaps back
        local sagMidX = midX
        local sagMidY = midY + snapSag

        -- Create curve for snap animation
        local segments = 12
        local points = {}
        local shadowPoints = {}

        local shadowOffsetX = 3
        local shadowOffsetY = 8

        for i = 0, segments do
            local t = i / segments
            local x = (1 - t) * (1 - t) * self.snapEndPos.x +
                      2 * (1 - t) * t * sagMidX +
                      t * t * currentX
            local y = (1 - t) * (1 - t) * self.snapEndPos.y +
                      2 * (1 - t) * t * sagMidY +
                      t * t * currentY

            table.insert(points, x)
            table.insert(points, y)
            table.insert(shadowPoints, x + shadowOffsetX)
            table.insert(shadowPoints, y + shadowOffsetY)
        end

        -- Fade out as it snaps
        local snapOpacity = 1 - progress

        -- Draw snap shadow
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 0, 0, snapOpacity * 0.2)
        love.graphics.line(shadowPoints)

        -- Draw snap line (same width, just brighter)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0.4, 0.8, 1.0, snapOpacity * 0.8)
        love.graphics.line(points)

        -- Reset graphics state
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
    end
end

return OxygenSystem
