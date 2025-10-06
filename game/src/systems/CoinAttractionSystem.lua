local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")

---@class CoinAttractionSystem : System
local CoinAttractionSystem = System:extend("CoinAttractionSystem", {"Position", "Movement", "Coin"})

---Update the coin attraction system
---@param dt number Delta time
function CoinAttractionSystem:update(dt)
    if not self.world then return end

     -- Get all coin entities using the tag system
     local coinEntities = self.world:getEntitiesWithTag("Coin")
     if #coinEntities == 0 then return end

    -- Get player entity using helper function
    local playerEntity = EntityUtils.findPlayer(self.world)
    if not playerEntity then return end

    local playerPosition = playerEntity:getComponent("Position")
    if not playerPosition then return end

    -- Process each coin for attraction
    for _, coinEntity in ipairs(coinEntities) do
        local coinPosition = coinEntity:getComponent("Position")
        local coinMovement = coinEntity:getComponent("Movement")
        local coinComponent = coinEntity:getComponent("Coin")

        if coinPosition and coinMovement and coinComponent and coinMovement.enabled then
            -- Check if enough time has passed since coin spawn (250ms delay)
            local currentTime = love.timer.getTime()
            local timeSinceSpawn = currentTime - coinComponent.spawnTime
            local attractionDelay = 0.25 -- 250ms delay

            if timeSinceSpawn >= attractionDelay then
                -- Calculate distance to player
                local dx = playerPosition.x - coinPosition.x
                local dy = playerPosition.y - coinPosition.y
                local distance = math.sqrt(dx * dx + dy * dy)

                -- Get the coin's specific attractor radius
                local attractorRadius = coinComponent:getAttractorRadius()

                -- If player is within attraction radius, move directly towards player
                if distance <= attractorRadius and distance > 0 then
                    -- Calculate movement speed with ease-in effect
                    local movementSpeed = self:calculateMovementSpeed(distance, attractorRadius)

                    -- Calculate direction to player (normalized)
                    local dirX = dx / distance
                    local dirY = dy / distance

                    -- Set velocity directly towards player (overrides any existing momentum/friction)
                    coinMovement:setVelocity(dirX * movementSpeed, dirY * movementSpeed)
                end
            end
        end
    end
end

---Calculate movement speed with ease-in effect for direct movement
---@param distance number Current distance to player
---@param maxRadius number Maximum attraction radius
---@return number Movement speed
function CoinAttractionSystem:calculateMovementSpeed(distance, maxRadius)
    -- Base movement speed
    local baseSpeed = 80 -- Base movement speed

    -- Calculate normalized distance (0 at player, 1 at edge of radius)
    local normalizedDistance = distance / maxRadius

    -- Ease-in effect: faster movement as coin gets closer
    -- Using a quadratic ease-in: 1 - (1 - t)^2
    local easeInFactor = 1 - (1 - (1 - normalizedDistance)) ^ 2

    -- Apply ease-in to movement speed (starts slow, gets faster as it approaches)
    local speed = baseSpeed * (0.3 + 0.7 * easeInFactor)

    return speed
end

return CoinAttractionSystem
