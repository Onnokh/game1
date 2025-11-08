local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")
local GameState = require("src.core.GameState")
local ShaderManager = require("src.core.managers.ShaderManager")
local GameController = require("src.core.GameController")
local PlayerConfig = require("src.entities.Player.PlayerConfig")
local CoordinateUtils = require("src.utils.coordinates")

---@class AimLineRenderSystem : System
---Renders an aiming line for ranged weapons from player to mouse cursor
local AimLineRenderSystem = System:extend("AimLineRenderSystem", {})

-- Laser styling and behaviour constants
local MAX_BEAM_LENGTH = 400    -- Maximum reach of the laser regardless of cursor distance
local MIN_RAY_LENGTH = 2       -- Avoid Box2D raycasts with extremely short segments
local BEAM_WIDTH = 1           -- Core thickness of the beam in pixels
local GLOW_WIDTH = 12          -- Total width of the glow area around the beam
local GLOW_FALLOFF = 2.2       -- Power falloff applied to the outer glow
local SOFT_EDGE = 3            -- Soft edge thickness applied to the beam core

-- Store the original new function
local originalNew = AimLineRenderSystem.new

---Create a new AimLineRenderSystem instance
---@return AimLineRenderSystem
function AimLineRenderSystem.new()
    local self = originalNew()
    self.isWorldSpace = false -- This system draws in screen space with world-to-screen conversion

    return self
end

---Draw the aiming line
function AimLineRenderSystem:draw()
    -- Don't draw aiming line when game is paused or over
    if GameController.paused or GameController.gameOver then
        return
    end

    -- Get the world reference
    local world = self.world
    if not world then
        return
    end

    -- Find the player entity
    local player = EntityUtils.findPlayer(world)
    if not player then
        return
    end

    -- Check if player has a weapon component
    local weapon = player:getComponent("Weapon")
    if not weapon then
        return
    end

    -- Get current weapon data
    local currentWeapon = weapon:getCurrentWeapon()
    if not currentWeapon then
        return
    end

    -- Only draw aim line for ranged weapons
    if currentWeapon.type ~= "ranged" then
        return
    end

    -- Get player position
    local position = player:getComponent("Position")
    if not position then
        return
    end

    -- Get player's sprite renderer and animator to get gun layer offset
    local spriteRenderer = player:getComponent("SpriteRenderer")
    local animator = player:getComponent("Animator")
    if not spriteRenderer or not animator then
        return
    end

    -- Get the gun layer offset (this already accounts for direction flipping)
    local gunOffset = animator:getLayerOffset("gun")
    local playerX = position.x + gunOffset.x
    local playerY = position.y + gunOffset.y + 3

    -- Get mouse position (use auto-aim position if active, otherwise real mouse position)
    local mouseX, mouseY
    if GameState.input.autoAim then
        -- Use auto-aim position from GameState
        mouseX = GameState.input.mouseX
        mouseY = GameState.input.mouseY
    else
        -- Use real mouse position
        local screenMouseX, screenMouseY = love.mouse.getPosition()
        mouseX, mouseY = CoordinateUtils.screenToWorld(screenMouseX, screenMouseY, GameState.camera)
    end

    -- Calculate direction from player to mouse
    local dx = mouseX - playerX
    local dy = mouseY - playerY
    local distanceToMouse = math.sqrt(dx * dx + dy * dy)

    if distanceToMouse < 1e-3 then
        return
    end

    local normalizedDx = dx / distanceToMouse
    local normalizedDy = dy / distanceToMouse

    -- Apply start offset in the aiming direction
    playerX = playerX + normalizedDx * PlayerConfig.START_OFFSET
    playerY = playerY + normalizedDy * PlayerConfig.START_OFFSET

    -- Base beam extends towards mouse but capped, accounting for start offset
    local maxReach = math.max(distanceToMouse - PlayerConfig.START_OFFSET, 0)
    local desiredLength = math.min(maxReach, MAX_BEAM_LENGTH)
    if desiredLength <= 0 then
        return
    end
    local endX = playerX + normalizedDx * desiredLength
    local endY = playerY + normalizedDy * desiredLength

    -- Perform raycasting to find collision point before the desired cursor reach
    local hitSomething = false
    local rayLength = MAX_BEAM_LENGTH

    if world.physicsWorld then
        local rayEndX = playerX + normalizedDx * rayLength
        local rayEndY = playerY + normalizedDy * rayLength

        if rayLength > MIN_RAY_LENGTH then
            world.physicsWorld:rayCast(playerX, playerY, rayEndX, rayEndY, function(fixture, x, y, xn, yn, fraction)
                local body = fixture:getBody()
                if body:getType() == "static" then
                    local hitLength = fraction * rayLength
                    if hitLength < desiredLength then
                        endX = x
                        endY = y
                        hitSomething = true
                        desiredLength = hitLength
                    end
                    return fraction
                end
                return 1
            end)
        end
    end

    -- Convert world coordinates to screen coordinates
    local screenStartX, screenStartY = CoordinateUtils.worldToScreen(playerX, playerY, GameState.camera)
    local screenEndX, screenEndY = CoordinateUtils.worldToScreen(endX, endY, GameState.camera)

    -- Get the shader
    local shader = ShaderManager.getShader("aim_line")
    if not shader then
        return -- Shader not loaded
    end

    -- Calculate bounding box covering entire screen for infinite line
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local minX = 0
    local minY = 0
    local width = screenWidth
    local height = screenHeight

    -- Draw in screen space (outside camera transform)
    love.graphics.push()
    love.graphics.origin()

    -- Set shader uniforms
    ---@type number[]
    local startVec = {screenStartX, screenStartY}
    ---@type number[]
    local endVec = {screenEndX, screenEndY}
    ---@type number[]
    local beamColor = {1.0, 0.1, 0.1}

    shader:send("startPos", startVec)
    shader:send("endPos", endVec)
    shader:send("beamColor", beamColor)
    shader:send("beamWidth", BEAM_WIDTH)
    shader:send("glowWidth", GLOW_WIDTH)
    shader:send("glowFalloff", GLOW_FALLOFF)
    shader:send("softEdge", SOFT_EDGE)
    shader:send("isHit", hitSomething)

    -- Draw rectangle covering the line area with shader
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", minX, minY, width, height)
    love.graphics.setShader()

    love.graphics.pop()

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
end

return AimLineRenderSystem

