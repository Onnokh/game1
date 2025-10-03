---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.sprites")
local LightWorld = require "shadows.LightWorld"
local Light = require "shadows.Light"
local Body = require("shadows.Body")
local PolygonShadow = require("shadows.ShadowShapes.PolygonShadow")

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
local debugWallBody = nil
local debugWallWidth, debugWallHeight = 32, 64
local debugWallCollider = nil

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
  lightWorld:SetColor(200, 200, 200, 255)
  GameScene.lightWorld = lightWorld

  -- Add a player light
  playerLight = Light:new(lightWorld, 160)
  playerLight:SetColor(255, 255, 255, 80)

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
    playerEntity = Player.create(gameState.player.x, gameState.player.y, ecsWorld, physicsWorld)

    -- Create input system with gameState input
    local inputSystem = InputSystem.new(gameState.input)
    ecsWorld:addSystem(inputSystem)

    -- Add mouse facing system (needs gameState)
    ecsWorld:addSystem(MouseFacingSystem.new(gameState))
  end

  -- Create a debug shadow-casting wall next to the player (once)
  if playerEntity and lightWorld and not debugWallBody then
    debugWallBody = Body:new(lightWorld)
    -- Position slightly to the right of the player
    local px, py = gameState.player.x, gameState.player.y
    debugWallBody:SetPosition(px + 64, py, 1)
    -- Rectangle 32x64 (origin at body's local 0,0)
    PolygonShadow:new(debugWallBody, 0, 0, 32, 0, 32, 64, 0, 64)

    -- Create a matching static physics collider for the debug wall
    if physicsWorld then
      local wx, wy = px + 64, py
      debugWallCollider = physicsWorld:newCollider("Rectangle", {
        wx + debugWallWidth / 2, wy + debugWallHeight / 2, debugWallWidth, debugWallHeight
      })
      debugWallCollider:setType("static")
      debugWallCollider:setRestitution(0.1)
      debugWallCollider:setFriction(0.8)

      -- Expose via borderColliders so it renders in the F3 overlay
      table.insert(borderColliders, debugWallCollider)
    end
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
  gameState.camera:setPosition(gameState.player.x, gameState.player.y)
  gameState.camera:setScale(scale)

  -- Update light position to follow player
  if playerLight and gameState.player then
    -- Position light at player's world coordinates (same coordinate system as mouse clicks)
    playerLight:SetPosition(gameState.player.x + gameState.player.width /2, gameState.player.y + gameState.player.height /2, 1)
  end

  -- Update light world to render lighting
  if lightWorld then
    -- Align LightWorld with camera so lights can use WORLD coordinates
    local camX, camY, scale = gameState.camera.x, gameState.camera.y, gameState.camera.scale
    local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    -- Shädows does: translate(-x*z, -y*z); scale(z,z)
    -- origin at camera top-left in world units
    local lwX = camX - (halfW / scale)
    local lwY = camY - (halfH / scale)

    lightWorld:SetPosition(lwX, lwY, scale)
    lightWorld:Update()
  end
end

-- Handle mouse clicks for debugging
function GameScene.mousepressed(x, y, button, gameState)
  if button == 1 then -- Left click
    print("Left click at:", x, y)
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

    -- Draw a red border around the debug wall
    if debugWallBody then
      local wx, wy = debugWallBody:GetPosition()
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", wx, wy, debugWallWidth, debugWallHeight)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end)
  -- Render Shädows lighting (outside camera transform to avoid double transforms)
  if lightWorld then
    lightWorld:Draw()
  end
end

return GameScene
