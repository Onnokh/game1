---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.sprites")

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

  -- Add systems to the ECS world (order matters!)
  ecsWorld:addSystem(MovementSystem.new())  -- First: handle movement and collision
  ecsWorld:addSystem(AnimationControllerSystem.new()) -- Second: control animations based on movement
  ecsWorld:addSystem(AnimationSystem.new()) -- Third: advance animations
  ecsWorld:addSystem(RenderSystem.new())    -- Fourth: render everything

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
        world[x][y] = 1 -- Grass
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
            tileX + tileSize/2, tileY + tileSize/2, tileSize, tileSize
          })
          collider:setType("static")
          collider:setRestitution(0.1) -- Slight bounce
          collider:setFriction(0.8) -- High friction

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
    ecsWorld:addSystem(MovementSystem.new())  -- First: handle movement and collision
    ecsWorld:addSystem(AnimationControllerSystem.new()) -- Second: control animations based on movement
    ecsWorld:addSystem(AnimationSystem.new()) -- Third: advance animations
    ecsWorld:addSystem(RenderSystem.new())    -- Fourth: render everything
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
end

-- Draw the game scene
function GameScene.draw(gameState)
  -- Apply camera transform
  love.graphics.push()
  love.graphics.scale(gameState.camera.scale, gameState.camera.scale)
  love.graphics.translate(-gameState.camera.x, -gameState.camera.y)

  -- Draw the world using Iffy
  sprites.drawWorld(world, worldWidth, worldHeight, tileSize, tileVariants)

  -- Draw ECS entities
  if ecsWorld then
    ecsWorld:draw()
  end


  love.graphics.pop()
end

return GameScene
