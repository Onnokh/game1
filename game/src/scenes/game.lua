---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.utils.sprites")
local LightWorld = require "shadows.LightWorld"

-- Use constants from the global constants module
local tileSize = GameConstants.TILE_SIZE
local worldWidth = GameConstants.WORLD_WIDTH
local worldHeight = GameConstants.WORLD_HEIGHT

-- ECS System
local World = require("src.core.World")
local MovementSystem = require("src.systems.MovementSystem")
local PathfindingSystem = require("src.systems.PathfindingSystem")
local RenderSystem = require("src.systems.RenderSystem")
local AnimationSystem = require("src.systems.AnimationSystem")
local ShadowSystem = require("src.systems.ShadowSystem")
local CollisionSystem = require("src.systems.CollisionSystem")
local MouseFacingSystem = require("src.systems.MouseFacingSystem")
local StateMachineSystem = require("src.systems.StateMachineSystem")
local AttackSystem = require("src.systems.AttackSystem")
local DamageSystem = require("src.systems.DamageSystem")
local FlashEffectSystem = require("src.systems.FlashEffectSystem")
local ParticleRenderSystem = require("src.systems.ParticleRenderSystem")
local ShaderManager = require("src.utils.ShaderManager")
local Player = require("src.entities.Player.Player")
local Skeleton = require("src.entities.Monsters.Skeleton.Skeleton")
local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local SpriteRenderer = require("src.components.SpriteRenderer")
local CastableShadow = require("src.components.CastableShadow")
local PathfindingCollision = require("src.components.PathfindingCollision")
local Animator = require("src.components.Animator")
local Reactor = require("src.entities.Reactor.Reactor")

local ecsWorld = nil
local uiWorld = nil
local playerEntity = nil
local monsters = {} -- Array of monster entities
local playerCollider = nil
local lightWorld = nil
local testBoxEntity = nil
local testBoxOverlayRegistered = false

-- Physics
local physicsWorld = nil
local borderColliders = {}

-- Expose physics variables for debug overlay
GameScene.physicsWorld = physicsWorld
GameScene.playerCollider = playerCollider
GameScene.borderColliders = borderColliders
GameScene.ecsWorld = ecsWorld
GameScene.monsters = monsters

-- Initialize the game scene
function GameScene.load()
  -- Load sprites with Iffy
  sprites.load()

  -- Load shaders
  ShaderManager.loadDefaultShaders()

  -- Initialize ECS world
  ecsWorld = World.new()
  -- Initialize UI world (separate from ECS)
  uiWorld = World.new()

  -- Initialize physics world (gravity: 0, 0 for top-down game)
  physicsWorld = love.physics.newWorld(0, 0, true)
  GameScene.physicsWorld = physicsWorld

  -- Initialize Shädows lighting system
  lightWorld = LightWorld:new()
  -- Dusk ambient lighting: cooler, slightly darker blue
  lightWorld:SetColor(70, 90, 140, 255)
  GameScene.lightWorld = lightWorld

  -- Add systems to the ECS world (order matters!)
  ecsWorld:addSystem(CollisionSystem.new(physicsWorld)) -- First: ensure colliders exist
  ecsWorld:addSystem(StateMachineSystem.new())         -- Second: update state machines
  ecsWorld:addSystem(MovementSystem.new())              -- Third: handle movement and collision
  ecsWorld:addSystem(AttackSystem.new())               -- Fourth: handle attacks
  ecsWorld:addSystem(require("src.systems.AttackColliderSystem").new()) -- Manage ephemeral attack colliders
  ecsWorld:addSystem(DamageSystem.new())               -- Fifth: process damage events (includes knockback)
  ecsWorld:addSystem(FlashEffectSystem.new())         -- Seventh: update flash effects
  ecsWorld:addSystem(AnimationSystem.new())           -- Eighth: advance animations
  ecsWorld:addSystem(ParticleRenderSystem.new())      -- Ninth: update particles
  ecsWorld:addSystem(ShadowSystem.new(lightWorld))    -- Tenth: update shadow bodies
  ecsWorld:addSystem(require("src.systems.LightSystem").new(lightWorld)) -- Manage dynamic lights
  ecsWorld:addSystem(RenderSystem.new())              -- Eleventh: render everything
  -- Damage numbers are now handled by UISystems.DamagePopupSystem

  -- Add UI systems to separate world
  local HealthBarSystem = require("src.systems.UISystems.HealthBarSystem")
  local HUDSystem = require("src.systems.UISystems.HUDSystem")
  local DamagePopupSystem = require("src.systems.UISystems.DamagePopupSystem")
  local MenuSystem = require("src.systems.UISystems.MenuSystem")

  local healthBarSystem = HealthBarSystem.new(ecsWorld)
  uiWorld:addSystem(healthBarSystem)
  uiWorld:addSystem(HUDSystem.new(ecsWorld, healthBarSystem)) -- Pass healthBarSystem reference
  uiWorld:addSystem(DamagePopupSystem.new(ecsWorld))
  uiWorld:addSystem(MenuSystem.new())

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

  -- Add a Reactor entity (64x64 = 4x4 tiles) via factory
  do
    local reactorTileX, reactorTileY = 24, 12 -- choose a free spot
    local reactorX = (reactorTileX - 1) * tileSize
    local reactorY = (reactorTileY - 1) * tileSize
    Reactor.create(reactorX, reactorY, ecsWorld, physicsWorld)
  end

  -- Add pathfinding system after static collision objects are added
  ecsWorld:addSystem(PathfindingSystem.new(world, worldWidth, worldHeight, tileSize)) -- Pathfinding system
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
          local body = love.physics.newBody(physicsWorld,
            tileX + tileSize / 2, tileY + tileSize / 2, "static")
          local shape = love.physics.newRectangleShape(tileSize, tileSize)
          local fixture = love.physics.newFixture(body, shape)
          fixture:setRestitution(0.1) -- Slight bounce
          fixture:setFriction(0.8)    -- High friction

          table.insert(borderColliders, {
            body = body,
            fixture = fixture,
            shape = shape
          })
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
    ecsWorld:addSystem(CollisionSystem.new(physicsWorld)) -- First: ensure colliders exist
    ecsWorld:addSystem(StateMachineSystem.new())         -- Second: update state machines
    ecsWorld:addSystem(MovementSystem.new())              -- Third: handle movement and collision
    ecsWorld:addSystem(AttackSystem.new())               -- Fourth: handle attacks
    ecsWorld:addSystem(require("src.systems.AttackColliderSystem").new()) -- Manage ephemeral attack colliders
    ecsWorld:addSystem(DamageSystem.new())               -- Fifth: process damage events (includes knockback)
    ecsWorld:addSystem(FlashEffectSystem.new())         -- Seventh: update flash effects
    ecsWorld:addSystem(AnimationSystem.new())           -- Eighth: advance animations
    ecsWorld:addSystem(ParticleRenderSystem.new())      -- Ninth: update particles
    ecsWorld:addSystem(ShadowSystem.new(lightWorld))    -- Tenth: update shadow bodies
    ecsWorld:addSystem(require("src.systems.LightSystem").new(lightWorld)) -- Manage dynamic lights
    ecsWorld:addSystem(RenderSystem.new())              -- Eleventh: render everything
    -- Damage numbers are now handled by UISystems.DamagePopupSystem

    if not uiWorld then
      uiWorld = World.new()
      local HealthBarSystem = require("src.systems.UISystems.HealthBarSystem")
      local HUDSystem = require("src.systems.UISystems.HUDSystem")
      local DamagePopupSystem = require("src.systems.UISystems.DamagePopupSystem")
      local MenuSystem = require("src.systems.UISystems.MenuSystem")

      local healthBarSystem = HealthBarSystem.new(ecsWorld)
      uiWorld:addSystem(healthBarSystem)
      uiWorld:addSystem(HUDSystem.new(ecsWorld, healthBarSystem)) -- Pass healthBarSystem reference
      uiWorld:addSystem(DamagePopupSystem.new(ecsWorld))
      uiWorld:addSystem(MenuSystem.new())
    end

  end

  -- Create player entity if it doesn't exist
  if not playerEntity and ecsWorld then
    playerEntity = Player.create(gameState.player.x, gameState.player.y, ecsWorld, physicsWorld)

    -- Add mouse facing system (needs gameState)
    ecsWorld:addSystem(MouseFacingSystem.new(gameState))
  end

  -- Create monsters if they don't exist
  if #monsters == 0 and ecsWorld then
      -- Create multiple skeletons at different positions
      local monsterPositions = {
          {x = 244, y = 260}, -- Original position
          {x = 300, y = 240}, -- Top right
          {x = 180, y = 300}, -- Bottom left
          {x = 350, y = 350}, -- Bottom right
      }

      for _, pos in ipairs(monsterPositions) do
          local skeleton = Skeleton.create(pos.x, pos.y, ecsWorld, physicsWorld)
          table.insert(monsters, skeleton)
      end
  end


  -- Update ECS world (handles movement, collision, rendering)
  if ecsWorld then
    ecsWorld:update(dt)
    -- Update the exposed reference
    GameScene.ecsWorld = ecsWorld
  end

  -- Update UI world separate from camera/lighting
  if uiWorld then
    uiWorld:update(dt)
  end

  -- Update physics world for collision detection only
  if physicsWorld then
    physicsWorld:update(dt)
  end

  -- Register test wall collider into debug overlay once created by CollisionSystem
  if not testBoxOverlayRegistered and testBoxEntity then
    local c = testBoxEntity:getComponent("Collision")
    if c and c:hasCollider() then
      table.insert(borderColliders, c.collider)
      testBoxOverlayRegistered = true
    end
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

  -- Set camera position directly
  gameState.camera:setPosition(gameState.player.x, gameState.player.y)
  gameState.camera:setScale(GameConstants.CAMERA_SCALE)

  -- Player light following is handled by LightSystem via the player's Light component

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

-- Add a new monster at the specified position
function GameScene.addMonster(x, y)
  if ecsWorld and physicsWorld then
    local skeleton = Skeleton.create(x, y, ecsWorld, physicsWorld)
    table.insert(monsters, skeleton)
    print("Added monster at:", x, y, "Total monsters:", #monsters)
  end
end

-- Handle mouse clicks for debugging
function GameScene.mousepressed(x, y, button, gameState)
  if button == 2 then -- Right click
    print("Right click at:", x, y)
    -- Add a monster at click position (convert screen to world coordinates)
    local worldX = gameState.camera.x + (x - love.graphics.getWidth() / 2) / gameState.camera.scale
    local worldY = gameState.camera.y + (y - love.graphics.getHeight() / 2) / gameState.camera.scale
    GameScene.addMonster(worldX, worldY)
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

    -- Render Shädows lighting (outside camera transform to avoid double transforms)
    if lightWorld then
      lightWorld:Draw()
    end

  end)
  -- Draw UI elements
  if uiWorld then
    -- First draw world-space UI elements (health bars) inside camera transform
    gameState.camera:draw(function()
      for _, system in ipairs(uiWorld.systems) do
        if system.isWorldSpace then
          system:draw()
        end
      end
    end)

    -- Then draw screen-space UI elements (HUD, menus) outside camera transform
    love.graphics.push()
    love.graphics.origin()
    for _, system in ipairs(uiWorld.systems) do
      if not system.isWorldSpace then
        system:draw()
      end
    end
    love.graphics.pop()
  end
end

return GameScene
