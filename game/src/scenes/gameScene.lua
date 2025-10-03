---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.sprites")
local shadows = require "shadows" -- 2D lighting library
local LightWorld = require "shadows.LightWorld"
local Light = require "shadows.Light"
_G.Light = Light

-- Use constants from the global constants module
local tileSize = GameConstants.TILE_SIZE
local worldWidth = GameConstants.WORLD_WIDTH
local worldHeight = GameConstants.WORLD_HEIGHT

-- ECS System
local World = require("src.ecs.World")
local MovementSystem = require("src.ecs.systems.MovementSystem")
local RenderSystem = require("src.ecs.systems.RenderSystem")
local AnimationSystem = require("src.ecs.systems.AnimationSystem")
local AnimationControllerSystem = require("src.ecs.systems.AnimationControllerSystem")
local MouseFacingSystem = require("src.ecs.systems.MouseFacingSystem")
local InputSystem = require("src.ecs.systems.InputSystem")
local Player = require("src.ecs.actors.Player")

local ecsWorld = nil
local playerEntity = nil
local playerCollider = nil
local lightWorld = nil
local playerLight = nil
local staticLight = nil
local clickLights = {} -- Store lights created by clicking

-- Physics
local bf = require("lib.breezefield")
local physicsWorld = nil
local borderColliders = {}

-- Expose physics variables for debug overlay
GameScene.physicsWorld = physicsWorld
GameScene.playerCollider = playerCollider
GameScene.borderColliders = borderColliders

-- Initialize the game scene
function GameScene.load()
  -- Load sprites with Iffy
  sprites.load()

  -- Initialize ECS world
  ecsWorld = World.new()

  -- Initialize physics world (gravity: 0, 0 for top-down game)
  physicsWorld = bf.newWorld(0, 0, true)
  GameScene.physicsWorld = physicsWorld

  -- Initialize Shädows lighting system
  lightWorld = LightWorld:new()
  lightWorld:SetColor(100, 100, 100, 255) -- Brighter ambient color (gray instead of black)
  GameScene.lightWorld = lightWorld
  _G.lightWorld = lightWorld

  -- Add a player light
  playerLight = Light:new(lightWorld, 300) -- Larger radius to be more visible
  playerLight:SetPosition(100, 100, 1) -- Start at player position
  playerLight:SetColor(255, 255, 255) -- white light
  playerLight.Blur = true -- Enable blur for better visibility
  _G.playerLight = playerLight

  -- Add a static light at tile (10, 20)
  staticLight = Light:new(lightWorld, 40) -- Medium radius
  staticLight:SetPosition(144, 304, 1) -- Tile (10, 20) = (144, 304)
  staticLight:SetColor(255, 200, 100) -- Orange/yellow light
  staticLight.Blur = true -- Enable blur for better visibility
  _G.clickLights = clickLights

  -- Add systems to the ECS world (order matters!)
  ecsWorld:addSystem(MovementSystem.new())            -- First: handle movement and collision
  ecsWorld:addSystem(AnimationControllerSystem.new()) -- Second: control animations based on movement
  ecsWorld:addSystem(AnimationSystem.new())           -- Third: advance animations
  ecsWorld:addSystem(RenderSystem.new())              -- Fourth: render everything

  -- Create a simple tile-based world
  for x = 1, worldWidth do
    world[x] = {}
    tileVariants[x] = {}
    for y = 1, worldHeight do
      -- Create a more interesting pattern with different tile types
      if x == 1 or x == worldWidth or y == 1 or y == worldHeight then
        world[x][y] = 3 -- Wall border
        -- Select appropriate cliff tile based on position (3x6 grid)
        if x == 1 and y == 1 then
          tileVariants[x][y] = 1 -- Top-left corner
        elseif x == worldWidth and y == 1 then
          tileVariants[x][y] = 3 -- Top-right corner
        elseif x == 1 and y == worldHeight then
          tileVariants[x][y] = 7 -- Bottom-left corner (row 5, col 1)
        elseif x == worldWidth and y == worldHeight then
          tileVariants[x][y] = 9 -- Bottom-right corner (row 5, col 3)
        elseif y == 1 then
          tileVariants[x][y] = 2 -- Top edge
        elseif y == worldHeight then
          tileVariants[x][y] = 8 -- Bottom edge (row 6, col 2)
        elseif x == 1 then
          tileVariants[x][y] = 4 -- Left edge (row 2, col 1)
        elseif x == worldWidth then
          tileVariants[x][y] = 6 -- Right edge (row 2, col 3)
        else
          tileVariants[x][y] = 8 -- Center (row 3, col 2)
        end
      else
        world[x][y] = 1        -- Grass
        tileVariants[x][y] = 1 -- Single grass tile variant
      end
    end
  end

  -- Create physics colliders for world borders
  GameScene.createBorderColliders()
  GameScene.borderColliders = borderColliders
end

-- Create static colliders for world border tiles
function GameScene.createBorderColliders()
  -- Clear existing border colliders
  borderColliders = {}

  -- Create colliders for border tiles
  for x = 1, worldWidth do
    for y = 1, worldHeight do
      if world[x][y] == 3 then -- Wall border tiles
        local tileX = (x - 1) * tileSize
        local tileY = (y - 1) * tileSize

        -- Create a rectangular collider for each border tile
        if physicsWorld then
          local collider = physicsWorld:newCollider("Rectangle", {
            tileX + tileSize / 2, tileY + tileSize / 2, tileSize, tileSize
          })
          collider:setType("static")
          collider:setRestitution(0.1) -- Slight bounce
          collider:setFriction(0.8)    -- High friction

          table.insert(borderColliders, collider)
        end
      end
    end
  end
end

-- Update the game scene
function GameScene.update(dt, gameState)
  -- Ensure ECS world is initialized
  if not ecsWorld then
    ecsWorld = World.new()
    ecsWorld:addSystem(MovementSystem.new())            -- First: handle movement and collision
    ecsWorld:addSystem(AnimationControllerSystem.new()) -- Second: control animations based on movement
    ecsWorld:addSystem(AnimationSystem.new())           -- Third: advance animations
    ecsWorld:addSystem(RenderSystem.new())              -- Fourth: render everything
  end

  -- Create player entity if it doesn't exist
  if not playerEntity and ecsWorld then
    print("=== PLAYER CREATION DEBUG ===")
    print("gameState.player.x:", gameState.player.x, "gameState.player.y:", gameState.player.y)
    print("Camera position:", gameState.camera.x, gameState.camera.y, "Scale:", gameState.camera.scale)

    playerEntity = Player.create(gameState.player.x, gameState.player.y, ecsWorld, physicsWorld)

    -- Check where player actually ended up
    local position = playerEntity:getComponent("Position")
    if position then
      print("Player actually created at:", position.x, position.y)
    end

    -- Create input system with gameState input
    local inputSystem = InputSystem.new(gameState.input)
    ecsWorld:addSystem(inputSystem)

    -- Add mouse facing system (needs gameState)
    ecsWorld:addSystem(MouseFacingSystem.new(gameState))
  end

  -- Update ECS world (handles movement, collision, rendering)
  if ecsWorld then
    ecsWorld:update(dt)
  end

  -- Update physics world for collision detection only
  if physicsWorld then
    physicsWorld:update(dt)
  end

  -- Update gameState for camera and other systems
  if playerEntity then
    local position = playerEntity:getComponent("Position")
    local movement = playerEntity:getComponent("Movement")
    local collision = playerEntity:getComponent("Collision")

    if position then
      gameState.player.x = position.x
      gameState.player.y = position.y
    end

    if movement then
      gameState.player.direction = movement.direction
    end

    -- Track player collider for debug overlay
    if collision and collision:hasCollider() then
      playerCollider = collision.collider
      GameScene.playerCollider = playerCollider
    end
  end

  -- Update camera and lightworld (match working implementation exactly)
  local scale = GameConstants.CAMERA_SCALE

  -- Set camera position directly (like the working implementation)
  gameState.camera.x = gameState.player.x
  gameState.camera.y = gameState.player.y
  gameState.camera:setScale(scale)

  -- Update light position to follow player
  if playerLight and gameState.player then
    -- Position light at player's world coordinates (same coordinate system as mouse clicks)
    playerLight:SetPosition(gameState.player.x, gameState.player.y, 1)

    -- Debug: Print light position occasionally
    if math.random() < 0.01 then -- 1% chance each frame
      local lightX, lightY, lightZ = playerLight:GetPosition()
      print("Light position:", lightX, lightY, lightZ, "Player position:", gameState.player.x, gameState.player.y)
    end
  end

  -- Update light world to render lighting
  if lightWorld then
    -- Align LightWorld with camera so lights can use WORLD coordinates
    local camX, camY, scale = gameState.camera.x, gameState.camera.y, gameState.camera.scale
    local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    -- Shädows does: translate(-x*z, -y*z); scale(z,z)
    -- Last working formula (correct speed, small offset):
    -- origin at camera top-left in world units
    local lwX = camX - (halfW / scale)
    local lwY = camY - (halfH / scale)
    -- Snap to integer pixels to avoid subpixel sampling artifacts
    lwX = math.floor(lwX + 0.5)
    lwY = math.floor(lwY + 0.5)
    lightWorld:SetPosition(lwX, lwY, scale)
    lightWorld:Update()
  end
end

-- Handle mouse clicks for debugging
function GameScene.mousepressed(x, y, button, gameState)
  if button == 1 then -- Left click
    local worldX, worldY = gameState.camera:toWorld(x, y)
    local scale = gameState.camera.scale or 1

    -- Simplified debug output
    print("=== MOUSE CLICK DEBUG ===")
    print("Screen click:", x, y)
    print("World coords:", worldX, worldY)
    print("Tile:", math.floor(worldX / tileSize) + 1, math.floor(worldY / tileSize) + 1)

    -- Create a new light at the clicked world position
    local newLight = Light:new(lightWorld, 150) -- Medium radius
    -- Snap spawn to integer pixels to avoid shader edge bleeding
    local lx = math.floor(worldX + 0.5)
    local ly = math.floor(worldY + 0.5)
    newLight:SetPosition(lx, ly, 1)
    newLight:SetColor(math.random(100, 255), math.random(100, 255), math.random(100, 255)) -- Random color
    newLight.Blur = true -- Enable blur for better visibility

    -- Store the light so it doesn't get garbage collected
    table.insert(clickLights, newLight)

    print("Created light at world coords:", worldX, worldY)
    print("Total lights:", #clickLights + 1) -- +1 for player light
    print("==========================")
  end
end

-- Draw the game scene
function GameScene.draw(gameState)
  -- Draw the world first
  gameState.camera:draw(function()
    -- Draw the world using Iffy (normal colors)
    sprites.drawWorld(world, worldWidth, worldHeight, tileSize, tileVariants)

    -- Draw ECS entities
    if ecsWorld then
      ecsWorld:draw()
    end

    -- Draw coordinate grid for debugging
    love.graphics.setColor(1, 1, 1, 0.3)
    for x = 0, worldWidth do
      local lineX = x * tileSize
      love.graphics.line(lineX, 0, lineX, worldHeight * tileSize)
    end
    for y = 0, worldHeight do
      local lineY = y * tileSize
      love.graphics.line(0, lineY, worldWidth * tileSize, lineY)
    end

    -- Draw tile numbers for debugging
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(5))
    for x = 1, worldWidth do
      for y = 1, worldHeight do
        local tileX = (x - 1) * tileSize + 2
        local tileY = (y - 1) * tileSize + 2
        love.graphics.print(x .. "," .. y, tileX, tileY)
      end
    end

    -- Render Shädows lighting is handled outside the camera transform
  end)

  -- Draw debug info on screen (not affected by camera)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(14))
  local mouseX, mouseY = love.mouse.getPosition()
  local worldX, worldY = gameState.camera:toWorld(mouseX, mouseY)
  local tileX = math.floor(worldX / tileSize) + 1
  local tileY = math.floor(worldY / tileSize) + 1

  love.graphics.print("Mouse: " .. mouseX .. ", " .. mouseY, 10, 10)
  love.graphics.print("World: " .. math.floor(worldX) .. ", " .. math.floor(worldY), 10, 30)
  love.graphics.print("Tile: " .. tileX .. ", " .. tileY, 10, 50)
  love.graphics.print("Camera: " .. math.floor(gameState.camera.x) .. ", " .. math.floor(gameState.camera.y), 10, 70)

  -- Lighting debug info
  if lightWorld then
    local lwX, lwY, lwZ = lightWorld:GetPosition()
    love.graphics.print("Light World: " .. math.floor(lwX) .. ", " .. math.floor(lwY) .. ", " .. lwZ, 10, 90)
    love.graphics.print("Total Lights: " .. (#clickLights + 1), 10, 110)
  end

  -- Render Shädows lighting (outside camera transform to avoid double transforms)
  if lightWorld then
    lightWorld:Draw()
  end
end

-- Helper functions for Lovebird diagnostics
if not _G.spawnLightScreen then
function _G.spawnLightScreen(sx, sy, radius, r, g, b)
  if not lightWorld then return end
  local L = Light:new(lightWorld, radius or 150)
  if r and g and b then L:SetColor(r, g, b) end
  L.Blur = true
  L:SetPosition(sx, sy, 1)
  table.insert(clickLights, L)
  return L
end
end

if not _G.spawnLightWorld then
function _G.spawnLightWorld(wx, wy, radius, r, g, b)
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local cx, cy = _G.gameState and _G.gameState.camera.x or 0, _G.gameState and _G.gameState.camera.y or 0
  local sx = wx - cx + w / 2
  local sy = wy - cy + h / 2
  return _G.spawnLightScreen(sx, sy, radius, r, g, b)
end
end

return GameScene
