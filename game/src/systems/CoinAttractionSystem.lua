local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")

---@class CoinAttractionSystem : System
local CoinAttractionSystem = System:extend("CoinAttractionSystem")

---Create a new CoinAttractionSystem
---@param world World The ECS world
---@return CoinAttractionSystem
function CoinAttractionSystem.new(world)
    ---@class CoinAttractionSystem
    local self = System.new()
    setmetatable(self, CoinAttractionSystem)
    self.world = world
    return self
end

---Update the coin attraction system
---@param dt number Delta time
function CoinAttractionSystem:update(dt)
    -- Get player entity using helper function
    local playerEntity = EntityUtils.findPlayer(self.world)
    if not playerEntity then return end

    local playerPosition = playerEntity:getComponent("Position")
    if not playerPosition then return end

    -- Get all coin entities using the tag system
    local coinEntities = self.world:getEntitiesWithTag("Coin")

    -- Debug: Check if we're finding coins
    if #coinEntities == 0 then
        print("CoinAttractionSystem: No coins found with tag 'Coin'")
        return
    else
        print("CoinAttractionSystem: Found " .. #coinEntities .. " coins")
    end

    -- Process each coin for attraction
    for _, coinEntity in ipairs(coinEntities) do
        local coinPosition = coinEntity:getComponent("Position")
        local coinMovement = coinEntity:getComponent("Movement")
        local coinComponent = coinEntity:getComponent("Coin")

        if coinPosition and coinMovement and coinComponent then
            -- Calculate distance to player
            local dx = playerPosition.x - coinPosition.x
            local dy = playerPosition.y - coinPosition.y
            local distance = math.sqrt(dx * dx + dy * dy)

            -- Get the coin's specific attractor radius
            local attractorRadius = coinComponent:getAttractorRadius()

            -- If player is within attraction radius, apply attraction force
            if distance <= attractorRadius and distance > 0 then
                -- Calculate attraction force (stronger when closer)
                local attractionStrength = 1.0 - (distance / attractorRadius) -- 0 to 1, stronger when closer
                local attractionForce = attractionStrength * 200 -- Base attraction force

                -- Calculate direction to player (normalized)
                local dirX = dx / distance
                local dirY = dy / distance

                -- Apply attraction force to coin's velocity
                local currentVelX = coinMovement.velocityX
                local currentVelY = coinMovement.velocityY
                local newVelX = currentVelX + (dirX * attractionForce * dt)
                local newVelY = currentVelY + (dirY * attractionForce * dt)

                coinMovement:setVelocity(newVelX, newVelY)
            end
        end
    end
end

return CoinAttractionSystem
