---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.sprites")
local Lighter = require "lib.init" -- 2D lighting library

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
local lighter = nil
local lightCanvas = nil
local playerLight = nil
local wall = nil

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

  -- Initialize lighter lighting system
  lighter = Lighter()
  lightCanvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

  GameScene.lighter = lighter
  GameScene.lightCanvas = lightCanvas

  -- Add some walls for shadows (example: a rectangle next to player)
  wall = {
    150, 100,
    200, 100,
    200, 150,
    150, 150
  }
  lighter:addPolygon(wall)

  -- Add a player light (start at player position)
  playerLight = lighter:addLight(0, 0, 1600, 1, 1, 1) -- bright white light

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

  -- Update lighter lighting - move player light to follow player
  if playerLight and gameState.player then
    lighter:updateLight(playerLight, gameState.player.x, gameState.player.y)
    print("Player:", gameState.player.x, gameState.player.y, "Light updated")
  end
end

-- Draw the game scene
function GameScene.draw(gameState)
  -- Use gamera's draw method to handle camera transforms
  gameState.camera:draw(function()
        -- Draw the world using Iffy (normal colors)
        sprites.drawWorld(world, worldWidth, worldHeight, tileSize, tileVariants)

        -- Draw ECS entities
        if ecsWorld then
          ecsWorld:draw()
        end

        -- Draw wall outline for debugging
        love.graphics.setColor(1, 0, 0, 1) -- Red color
        love.graphics.polygon("line", wall)
        love.graphics.setColor(1, 1, 1, 1) -- Reset to white
  end)

  -- Render lighting outside camera transform but with proper coordinates
  if lighter and lightCanvas then
    -- Convert player world position to screen position for lighting
    local screenX, screenY = gameState.camera:toScreen(gameState.player.x, gameState.player.y)

      -- Draw lights to canvas with global illumination
      love.graphics.setCanvas({lightCanvas, stencil = true})
      love.graphics.clear(0.3, 0.3, 0.3) -- Brighter global illumination

    -- Temporarily update light to screen coordinates for rendering
    if playerLight then
      lighter:updateLight(playerLight, screenX, screenY)

      -- Convert wall coordinates to screen space
      local wallScreen = {}
      for i = 1, #wall, 2 do
        local wallScreenX, wallScreenY = gameState.camera:toScreen(wall[i], wall[i + 1])
        wallScreen[#wallScreen + 1] = wallScreenX
        wallScreen[#wallScreen + 1] = wallScreenY
      end

      -- Remove old wall and add screen-space wall
      lighter:removePolygon(wall)
      lighter:addPolygon(wallScreen)

      lighter:drawLights()

      -- Restore to world coordinates
      lighter:updateLight(playerLight, gameState.player.x, gameState.player.y)
      lighter:removePolygon(wallScreen)
      lighter:addPolygon(wall)
    else
      lighter:drawLights()
    end

    love.graphics.setCanvas()

    -- Apply lighting as multiply blend
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(lightCanvas)
    love.graphics.setBlendMode("alpha")
  end
end

return GameScene
