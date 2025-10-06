---@class GameScene
local GameScene = {}

-- Scene state
local world = {}
local tileVariants = {} -- Store sprite variants for each tile
local GameConstants = require("src.constants")
local sprites = require("src.utils.sprites")
local WorldLight = require("src.utils.worldlight")

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
local GroundShadowSystem = require("src.systems.GroundShadowSystem")
local ShadowSystem = require("src.systems.ShadowSystem")
local CollisionSystem = require("src.systems.CollisionSystem")
local MouseFacingSystem = require("src.systems.MouseFacingSystem")
local StateMachineSystem = require("src.systems.StateMachineSystem")
local AttackSystem = require("src.systems.AttackSystem")
local DamageSystem = require("src.systems.DamageSystem")
local FlashEffectSystem = require("src.systems.FlashEffectSystem")
local ParticleRenderSystem = require("src.systems.ParticleRenderSystem")
local LootSystem = require("src.systems.LootSystem")
local CoinPickupSystem = require("src.systems.CoinPickupSystem")
local CoinAttractionSystem = require("src.systems.CoinAttractionSystem")
local AttackColliderSystem = require("src.systems.AttackColliderSystem")
local LightSystem = require("src.systems.LightSystem")
local OxygenSystem = require("src.systems.OxygenSystem")
local InteractionSystem = require("src.systems.InteractionSystem")
local ShaderManager = require("src.utils.ShaderManager")
local Player = require("src.entities.Player.Player")
local Skeleton = require("src.entities.Monsters.Skeleton.Skeleton")
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
GameScene.lightWorld = nil

-- Initialize the game scene
function GameScene.load()
  sprites.load()
  ShaderManager.loadDefaultShaders()

  -- Initialize physics world (gravity: 0, 0 for top-down game)
  physicsWorld = love.physics.newWorld(0, 0, true)
  GameScene.physicsWorld = physicsWorld

  -- Initialize Shädows lighting system via WorldLight manager
  lightWorld = WorldLight.init()
  GameScene.lightWorld = lightWorld

  -- Initialize ECS world with physics and light world references
  ecsWorld = World.new(physicsWorld, lightWorld)
  -- Initialize UI world (separate from ECS)
  uiWorld = World.new()

  -- Add systems to the ECS world (order matters!)
  ecsWorld:addSystem(CollisionSystem.new()) -- Ensure colliders exist
  ecsWorld:addSystem(StateMachineSystem.new()) -- Update state machines
  ecsWorld:addSystem(MovementSystem.new()) -- Handle movement and collision
  ecsWorld:addSystem(AttackSystem.new()) -- Handle attacks
  ecsWorld:addSystem(AttackColliderSystem.new()) -- Manage ephemeral attack colliders
  ecsWorld:addSystem(DamageSystem.new()) -- Process damage events (includes knockback)
  ecsWorld:addSystem(LootSystem.new()) -- Handle loot drops when entities die
  ecsWorld:addSystem(CoinPickupSystem.new()) -- Handle coin pickup collisions
  ecsWorld:addSystem(CoinAttractionSystem.new()) -- Handle coin attraction to player
  ecsWorld:addSystem(OxygenSystem.new()) -- Handle oxygen decay when outside reactor zone
  ecsWorld:addSystem(InteractionSystem.new()) -- Handle interactions with interactable entities
  ecsWorld:addSystem(FlashEffectSystem.new()) -- Update flash effects
  ecsWorld:addSystem(AnimationSystem.new()) -- Advance animations
  ecsWorld:addSystem(ParticleRenderSystem.new()) -- Update particles
  ecsWorld:addSystem(ShadowSystem.new()) -- Update shadow bodies
  ecsWorld:addSystem(LightSystem.new()) -- Manage dynamic lights
  ecsWorld:addSystem(GroundShadowSystem.new()) -- Draw ground shadows beneath sprites
  ecsWorld:addSystem(RenderSystem.new()) -- Render sprites and debug visuals

  -- Add UI systems to separate world
  local HealthBarSystem = require("src.systems.UISystems.HealthBarSystem")
  local HUDSystem = require("src.systems.UISystems.HUDSystem")
  local PhaseTextSystem = require("src.systems.UISystems.PhaseTextSystem")
  local CoinCounterSystem = require("src.systems.UISystems.CoinCounterSystem")
  local DamagePopupSystem = require("src.systems.UISystems.DamagePopupSystem")
  local LootPickupLabelSystem = require("src.systems.UISystems.LootPickupLabelSystem")
  local MenuSystem = require("src.systems.UISystems.MenuSystem")
  local PauseMenuSystem = require("src.systems.UISystems.PauseMenuSystem")
  local GameOverSystem = require("src.systems.UISystems.GameOverSystem")
  local SiegeCounterSystem = require("src.systems.UISystems.SiegeCounterSystem")
  local OxygenCounterSystem = require("src.systems.UISystems.OxygenCounterSystem")
  local InteractionPromptSystem = require("src.systems.UISystems.InteractionPromptSystem")
  local SafezoneVignetteSystem = require("src.systems.UISystems.SafezoneVignetteSystem")

  local healthBarSystem = HealthBarSystem.new(ecsWorld)
  uiWorld:addSystem(healthBarSystem)
  uiWorld:addSystem(HUDSystem.new(ecsWorld, healthBarSystem)) -- Pass healthBarSystem reference
  uiWorld:addSystem(CoinCounterSystem.new())
  uiWorld:addSystem(OxygenCounterSystem.new(ecsWorld))
  uiWorld:addSystem(PhaseTextSystem.new())
  uiWorld:addSystem(DamagePopupSystem.new(ecsWorld))
  uiWorld:addSystem(LootPickupLabelSystem.new(ecsWorld))
  uiWorld:addSystem(MenuSystem.new())
  uiWorld:addSystem(PauseMenuSystem.new())
  uiWorld:addSystem(GameOverSystem.new())
  uiWorld:addSystem(SiegeCounterSystem.new())
  uiWorld:addSystem(InteractionPromptSystem.new(ecsWorld))
  uiWorld:addSystem(SafezoneVignetteSystem.new(ecsWorld))

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

-- Allow other modules (phases, etc.) to set ambient color safely
function GameScene.setAmbientColor(r, g, b, a, duration)
  WorldLight.setAmbientColor(r, g, b, a, duration)
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

  -- If the scene hasn't been loaded yet, skip updating
  if not ecsWorld or not uiWorld or not physicsWorld then
    return
  end

  -- Create player entity if it doesn't exist
  if not playerEntity and ecsWorld then
    playerEntity = Player.create(gameState.player.x, gameState.player.y, ecsWorld, physicsWorld)

    -- Add mouse facing system (needs gameState)
    ecsWorld:addSystem(MouseFacingSystem.new(gameState))
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
    local spriteRenderer = playerEntity:getComponent("SpriteRenderer")

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

    -- Set camera position centered on player sprite
    if position and spriteRenderer then
      local centerX = position.x + spriteRenderer.width / 2
      local centerY = position.y + spriteRenderer.height / 2
      gameState.camera:setPosition(centerX, centerY)
    end
  end

  gameState.camera:setScale(GameConstants.CAMERA_SCALE)

  -- Update world light (position and ambient tween)
  WorldLight.update(dt, gameState.camera)
end

-- Update only UI systems (used when game is paused)
function GameScene.updateUI(dt, gameState)
  -- Update UI world separate from camera/lighting
  if uiWorld then
    uiWorld:update(dt)
  end
end

-- Add a new monster at the specified position
function GameScene.addMonster(x, y)
  if ecsWorld and physicsWorld then
    local skeleton = Skeleton.create(x, y, ecsWorld, physicsWorld)
    table.insert(monsters, skeleton)
    print("Added monster at:", x, y, "Total monsters:", #monsters)
    return skeleton
  end
  return nil
end

-- Handle mouse clicks for debugging
function GameScene.mousepressed(x, y, button, gameState)
  -- First check if pause menu can handle the click
  if uiWorld then
    for _, system in ipairs(uiWorld.systems) do
      if system.handleMouseClick then
        local handled = system:handleMouseClick(x, y, button)
        if handled then
          return -- Pause menu handled the click, don't process further
        end
      end
    end
  end

  -- If not handled by UI systems, process game logic
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

-- Cleanup the game scene when switching away
function GameScene.cleanup()
  print("GameScene: Cleaning up...")

  -- Clear monsters array
  monsters = {}

  -- Clear border colliders
  borderColliders = {}

  -- Destroy physics world (this will destroy all bodies, shapes, etc.)
  if physicsWorld then
    physicsWorld:destroy()
    physicsWorld = nil
    GameScene.physicsWorld = nil
  end

  -- Cleanup light world via manager
  if lightWorld then
    WorldLight.cleanup()
    lightWorld = nil
    GameScene.lightWorld = nil
  end

  -- Clear ECS world
  if ecsWorld then
    -- Try to cleanup ECS systems that might have canvases
    for _, system in ipairs(ecsWorld.systems) do
      if system.cleanup then
        system.cleanup()
      end
    end
    ecsWorld = nil
    GameScene.ecsWorld = nil
  end

  -- Clear UI world
  if uiWorld then
    -- Try to cleanup UI systems that might have canvases
    for _, system in ipairs(uiWorld.systems) do
      if system.cleanup then
        system.cleanup()
      end
    end
    uiWorld = nil
  end

  -- Clear entity references
  playerEntity = nil
  testBoxEntity = nil
  testBoxOverlayRegistered = false
  playerCollider = nil
  GameScene.playerCollider = nil
  GameScene.borderColliders = nil
  GameScene.monsters = nil

  -- Force Love2D to reset graphics state and release canvases
  love.graphics.reset()

  -- Force garbage collection to clean up any remaining references
  collectgarbage("collect")

  print("GameScene: Cleanup complete")
end

return GameScene
