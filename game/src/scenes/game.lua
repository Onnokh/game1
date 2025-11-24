---@class GameScene
local GameScene = {}

-- Scene state
local world = {} -- For pathfinding and collision detection
local GameConstants = require("src.constants")
---@type PlayerConfig
local PlayerConfig = require("src.entities.Player.PlayerConfig")
local sprites = require("src.utils.sprites")
local WorldLight = require("src.utils.worldlight")
local MapManager = require("src.core.managers.MapManager")
local CameraManager = require("src.core.managers.CameraManager")
local GameState = require("src.core.GameState")

-- ECS System
local World = require("src.core.World")
local MovementSystem = require("src.systems.MovementSystem")
local PathfindingSystem = require("src.systems.PathfindingSystem")
local RenderSystem = require("src.systems.RenderSystem")
local AnimationSystem = require("src.systems.AnimationSystem")
local GroundShadowSystem = require("src.systems.GroundShadowSystem")
local CollisionSystem = require("src.systems.CollisionSystem")
local TriggerZoneSystem = require("src.systems.TriggerZoneSystem")
local MouseFacingSystem = require("src.systems.MouseFacingSystem")
local GunRotationSystem = require("src.systems.GunRotationSystem")
local StateMachineSystem = require("src.systems.StateMachineSystem")
local AttackSystem = require("src.systems.AttackSystem")
local BulletSystem = require("src.systems.BulletSystem")
local AbilitySystem = require("src.systems.AbilitySystem")
local DamageSystem = require("src.systems.DamageSystem")
local FlashEffectSystem = require("src.systems.FlashEffectSystem")
local ParticleRenderSystem = require("src.systems.ParticleRenderSystem")
local LootSystem = require("src.systems.LootSystem")
local CoinPickupSystem = require("src.systems.CoinPickupSystem")
local CoinAttractionSystem = require("src.systems.CoinAttractionSystem")
local AttackColliderSystem = require("src.systems.AttackColliderSystem")
local LightSystem = require("src.systems.LightSystem")
local FireflySystem = require("src.systems.FireflySystem")
local InteractionSystem = require("src.systems.InteractionSystem")
local EventSystem = require("src.systems.EventSystem")
local AimLineRenderSystem = require("src.systems.AimLineRenderSystem")
local DashShadowSystem = require("src.systems.DashShadowSystem")
local DashShadowRenderSystem = require("src.systems.DashShadowRenderSystem")
  local DashChargesSystem = require("src.systems.DashChargesSystem")
  local ShaderManager = require("src.core.managers.ShaderManager")
local FootprintsSystem = require("src.systems.FootprintsSystem")
local EnemySpawnerSystem = require("src.systems.EnemySpawnerSystem")
local WaveTimerSystem = require("src.systems.UISystems.WaveTimerSystem")
local AutoAimSystem = require("src.systems.AutoAimSystem")
-- Use constants from the global constants module
local tileSize = GameConstants.TILE_SIZE
local worldWidth = 0  -- Will be set by loaded map
local worldHeight = 0  -- Will be set by loaded map
local ecsWorld = nil
local uiWorld = nil
local playerEntity = nil
local monsters = {} -- Array of monster entities
local playerCollider = nil
local lightWorld = nil
local mouseFacingSystemAdded = false -- Track if MouseFacingSystem has been added

---@type LookAheadController
local cameraLookAheadController
cameraLookAheadController = CameraManager.createLookAheadController({
  maxDistance = PlayerConfig.AIM_LINE_MAX_LENGTH or 100,
  lookAheadDistance = PlayerConfig.CAMERA_LOOK_AHEAD_DISTANCE or 100,
  deadzone = (PlayerConfig.CAMERA_LOOK_AHEAD_DEADZONE_FACTOR or 0.15) * GameConstants.TILE_SIZE,
  smoothSpeed = PlayerConfig.CAMERA_LOOK_AHEAD_SMOOTH_SPEED or 10
})
---@cast cameraLookAheadController LookAheadController

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

local function calculateDefaultCameraScale()
  return GameConstants.CAMERA_SCALE or 1.0
end

-- Initialize the game scene
function GameScene.load()
  sprites.load()
  ShaderManager.loadDefaultShaders()

  if cameraLookAheadController then
    ---@diagnostic disable-next-line:undefined-field
    cameraLookAheadController:reset()
  end

  -- Initialize physics world (gravity: 0, 0 for top-down game)
  physicsWorld = love.physics.newWorld(0, 0, true)
  GameScene.physicsWorld = physicsWorld

  -- Get lighting system (initialized in main.lua with pixel canvas dimensions)
  lightWorld = WorldLight.get()
  GameScene.lightWorld = lightWorld

  -- Set bright ambient lighting for the world
  -- This allows lights to be visible while keeping the world bright
  WorldLight.setAmbientColor(230, 230, 230, 255, 0) -- R,G,B values 0-255 (~90% brightness), final argument = duration (0 = instant)

  -- Initialize ECS world with physics reference
  ecsWorld = World.new(physicsWorld, lightWorld, false)
  -- Initialize UI world (separate from ECS, with drawOrder enabled for z-layering)
  uiWorld = World.new(nil, nil, true)

  -- Add systems to the ECS world (order matters!)
  ecsWorld:addSystem(CollisionSystem.new()) -- Ensure colliders exist
  ecsWorld:addSystem(TriggerZoneSystem.new()) -- Handle trigger zone callbacks
  ecsWorld:addSystem(StateMachineSystem.new()) -- Update state machines
  ecsWorld:addSystem(DashChargesSystem.new()) -- Update dash charge regeneration
  ecsWorld:addSystem(DashShadowSystem.new()) -- Update dash shadows
  ecsWorld:addSystem(MovementSystem.new()) -- Handle movement and collision
  ecsWorld:addSystem(AbilitySystem.new()) -- Handle ability switching and syncing
  ecsWorld:addSystem(AutoAimSystem.new()) -- Handle auto-aim targeting (must run before AttackSystem)
  ecsWorld:addSystem(AttackSystem.new()) -- Handle attacks
  ecsWorld:addSystem(BulletSystem.new()) -- Handle bullet movement and collision
  ecsWorld:addSystem(AttackColliderSystem.new()) -- Manage ephemeral attack colliders
  ecsWorld:addSystem(DamageSystem.new()) -- Process damage events (includes knockback)
  ecsWorld:addSystem(LootSystem.new()) -- Handle loot drops when entities die
  ecsWorld:addSystem(CoinPickupSystem.new()) -- Handle coin pickup collisions
  ecsWorld:addSystem(CoinAttractionSystem.new()) -- Handle coin attraction to player
  ecsWorld:addSystem(InteractionSystem.new()) -- Handle interactions with interactable entities
  ecsWorld:addSystem(EventSystem.new(ecsWorld)) -- Manage event lifecycle and animations
  ecsWorld:addSystem(FlashEffectSystem.new()) -- Update flash effects
  ecsWorld:addSystem(AnimationSystem.new()) -- Advance animations
  ecsWorld:addSystem(LightSystem.new()) -- Manage dynamic lights
  local fireflySystem = FireflySystem.new() -- Manage firefly spawning and movement
  ecsWorld:addSystem(fireflySystem)
  -- GroundShadowSystem is now a configuration module, shadows rendered in RenderSystem
  ecsWorld:addSystem(FootprintsSystem.new()) -- Draw footprints below sprites
  ecsWorld:addSystem(DashShadowRenderSystem.new()) -- Render dash shadows
  ecsWorld:addSystem(RenderSystem.new()) -- Render sprites and debug visuals
  ecsWorld:addSystem(ParticleRenderSystem.new()) -- Render particles above sprites
  -- Note: AimLineRenderSystem is a screen-space system but needs to stay in ECS world
  -- to access player and physics world for raycasting
  local aimLineSystem = AimLineRenderSystem.new()
  aimLineSystem.isWorldSpace = false
  ecsWorld:addSystem(aimLineSystem) -- Draw aiming line for ranged abilities
  GameScene.aimLineSystem = aimLineSystem

  -- Debug: count RenderSystem instances
  do
    local count = 0
    for _, sys in ipairs(ecsWorld.systems) do
      if tostring(sys.__name or ""):match("RenderSystem") then
        count = count + 1
      end
    end
    print(string.format("[Debug] RenderSystem instances: %d", count))
  end

  -- Add UI systems to separate world
  local HealthBarSystem = require("src.systems.UISystems.HealthBarSystem")
  local HUDSystem = require("src.systems.UISystems.HUDSystem")
  local ActionBarSystem = require("src.systems.UISystems.ActionBarSystem")
  local CoinCounterSystem = require("src.systems.UISystems.CoinCounterSystem")
  local InventoryDisplaySystem = require("src.systems.UISystems.InventoryDisplaySystem")
  local DamagePopupSystem = require("src.systems.UISystems.DamagePopupSystem")
  local LootPickupLabelSystem = require("src.systems.UISystems.LootPickupLabelSystem")
  local MenuSystem = require("src.systems.UISystems.MenuSystem")
  local PauseMenuSystem = require("src.systems.UISystems.PauseMenuSystem")
  local GameOverSystem = require("src.systems.UISystems.GameOverSystem")
  local EliteIndicatorSystem = require("src.systems.UISystems.EliteIndicatorSystem")
  local InteractionPromptSystem = require("src.systems.UISystems.InteractionPromptSystem")
  local AggroVignetteSystem = require("src.systems.UISystems.AggroVignetteSystem")
  local DashSpeedLinesSystem = require("src.systems.UISystems.DashSpeedLinesSystem")
  local ShopUISystem = require("src.systems.UISystems.ShopUISystem")
  local UpgradeUISystem = require("src.systems.UISystems.UpgradeUISystem")
  local MinimapSystem = require("src.systems.UISystems.MinimapSystem")

  local healthBarSystem = HealthBarSystem.new(ecsWorld)
  uiWorld:addSystem(MenuSystem.new()) -- Menu systems first to consume clicks
  uiWorld:addSystem(PauseMenuSystem.new())
  uiWorld:addSystem(GameOverSystem.new())

  uiWorld:addSystem(healthBarSystem)
  uiWorld:addSystem(WaveTimerSystem.new(ecsWorld)) -- Display game time at center-top
  uiWorld:addSystem(EliteIndicatorSystem.new(ecsWorld)) -- Draw elite indicators below other UI
  uiWorld:addSystem(HUDSystem.new(ecsWorld, healthBarSystem)) -- Pass healthBarSystem reference (includes dash charges)
  uiWorld:addSystem(ActionBarSystem.new(ecsWorld)) -- Action bar with ability slots
  uiWorld:addSystem(CoinCounterSystem.new())
  uiWorld:addSystem(InventoryDisplaySystem.new(ecsWorld))
  uiWorld:addSystem(DamagePopupSystem.new(ecsWorld))
  uiWorld:addSystem(LootPickupLabelSystem.new(ecsWorld))
  uiWorld:addSystem(ShopUISystem.new(ecsWorld)) -- After menus so clicks are blocked when paused
  uiWorld:addSystem(UpgradeUISystem.new(ecsWorld)) -- Crystal upgrade UI system
  uiWorld:addSystem(InteractionPromptSystem.new(ecsWorld))
  uiWorld:addSystem(AggroVignetteSystem.new(ecsWorld)) -- Show vignette when mobs are chasing player
  uiWorld:addSystem(DashSpeedLinesSystem.new(ecsWorld)) -- Show speed lines when player is dashing
  uiWorld:addSystem(MinimapSystem.new(ecsWorld)) -- Show minimap with shops and upgrade stations

  -- Load complete world using MapManager (handles everything: world generation, pathfinding, collisions, entities, camera)
  -- Check if we're loading from a save (which would have a specific seed)
  local SaveSystem = require("src.utils.SaveSystem")
  local savedSeed = SaveSystem.getPendingMapSeed()
  local skipEntitySpawn = SaveSystem.pendingLoadData ~= nil -- Skip entity spawn if loading from save
  local worldData = MapManager.load("src/levels/level1", physicsWorld, ecsWorld, savedSeed, skipEntitySpawn)

  -- Extract world data
  world = worldData.grid
  worldWidth = worldData.gridWidth
  worldHeight = worldData.gridHeight
  tileSize = worldData.tileSize
  playerEntity = worldData.playerEntity -- Will be nil if loading from save (updated later)
  borderColliders = worldData.collisionBodies
  GameState.camera = worldData.camera

  -- Set camera on ECS world for frustum culling in systems (e.g., LightSystem)
  ecsWorld:setCamera(GameState.camera)

  -- Set world grid for FireflySystem
  if fireflySystem then
    fireflySystem:setWorldGrid(world, tileSize)
    -- Set world bounds for fireflies (600x600)
    fireflySystem:setWorldBounds(0, 0, worldWidth, worldHeight)
  end

  -- Store references for debugging
  GameScene.borderColliders = borderColliders

  -- Store map data in GameState for debugging (overlay needs this)
  GameState.mapData = {
    width = worldWidth,
    height = worldHeight,
    tileSize = tileSize,
    collisionGrid = world
  }

  -- Generate minimap terrain once (static terrain rendered to canvas)
  local Minimap = require("src.ui.Minimap")
  Minimap.generateWorldTerrain()

  -- Create global particle entity for bullet impacts and other effects
  do
    local Entity = require("src.core.Entity")
    local ParticleSystem = require("src.components.ParticleSystem")
    local particleEntity = Entity.new()
    particleEntity:addTag("GlobalParticles")
    particleEntity:addComponent("ParticleSystem", ParticleSystem.new(200, 0, 0))
    ecsWorld:addEntity(particleEntity)
  end

  -- Add pathfinding system after static collision objects are added
  local pathfindingStart = love.timer.getTime()
  ecsWorld:addSystem(PathfindingSystem.new(world, worldWidth, worldHeight, tileSize))
  print(string.format("[GameScene] Pathfinding system init took %.2fs", love.timer.getTime() - pathfindingStart))

  -- Add EnemySpawnerSystem after PathfindingSystem so it can access the grid for validation
  ecsWorld:addSystem(EnemySpawnerSystem.new(ecsWorld, physicsWorld))

  -- Spawn a tree
  local Tree = require("src.entities.Decoration.Tree")
  local Tree2 = require("src.entities.Decoration.Tree2")
  local TreeStump = require("src.entities.Decoration.TreeStump")
  local Torch = require("src.entities.Decoration.Torch")
  local Barrel = require("src.entities.Decoration.Barrel")

  Tree.create(330, 320, ecsWorld, physicsWorld)
  Tree2.create(300, 300, ecsWorld, physicsWorld)
  TreeStump.create(360, 420, ecsWorld, physicsWorld)
  Torch.create(200, 420, ecsWorld, physicsWorld)
  Barrel.create(230, 380, ecsWorld, physicsWorld)

  -- Check if there's pending save data to load
  local SaveSystem = require("src.utils.SaveSystem")
  if SaveSystem.pendingLoadData then
    print("[GameScene] Restoring game state from save...")
    local success, restoredPlayer = SaveSystem.restoreGameState(ecsWorld, physicsWorld)

    -- Update player entity reference so camera can follow it
    if success and restoredPlayer then
      playerEntity = restoredPlayer
      print("[GameScene] Player entity reference updated for camera tracking")
    end
  end
end

-- Allow other modules (phases, etc.) to set ambient color safely
function GameScene.setAmbientColor(r, g, b, a, duration)
  WorldLight.setAmbientColor(r, g, b, a, duration)
end



-- Update the game scene
function GameScene.update(dt, gameState)

  -- If the scene hasn't been loaded yet, skip updating
  if not ecsWorld or not uiWorld or not physicsWorld then
    return
  end

  -- Add mouse facing system once player exists (needs gameState)
  if playerEntity and not mouseFacingSystemAdded then
    ecsWorld:addSystem(MouseFacingSystem.new(gameState))
    ecsWorld:addSystem(GunRotationSystem.new(gameState))
    mouseFacingSystemAdded = true
  end

  -- Update all maps through MapManager (with camera culling)
  MapManager.update(dt, gameState.camera)

  -- Update game time manager
  if gameState.gameTimeManager then
    gameState.gameTimeManager.update(dt)
  end

  -- Update physics world FIRST so positions are current
  if physicsWorld then
    physicsWorld:update(dt)
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

  -- Update camera to follow player
  if playerEntity then
    local collision = playerEntity:getComponent("Collision")

    -- Track player collider for debug overlay
    if collision and collision:hasCollider() then
      playerCollider = collision.collider
      GameScene.playerCollider = playerCollider
    end

  end

  -- Use debug camera scale if set, otherwise derive from zoom settings
  local overlayStats = require("lib.overlayStats")
  local defaultScale = calculateDefaultCameraScale()
  local targetScale = overlayStats.debugCameraScale or defaultScale
  gameState.camera:setScale(targetScale)

  -- Set camera position centered on player sprite AFTER scale is set
  -- This ensures the position clamping respects the correct zoom level
  if playerEntity then
    local position = playerEntity:getComponent("Position")
    local spriteRenderer = playerEntity:getComponent("SpriteRenderer")
    if position and spriteRenderer then
      local centerX = position.x + spriteRenderer.width / 2
      local centerY = position.y + spriteRenderer.height / 2
      local aimX, aimY = centerX, centerY
      if gameState and gameState.input then
        aimX = gameState.input.mouseX or centerX
        aimY = gameState.input.mouseY or centerY
      end
      if cameraLookAheadController then
        ---@diagnostic disable-next-line:undefined-field
        cameraLookAheadController:update(gameState.camera, centerX, centerY, aimX, aimY, dt)
      else
        gameState.camera:setPosition(centerX, centerY)
      end
    end
  end

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

-- Get map data (collision grid and dimensions)
function GameScene.getMapData()
  -- Return the FULL world grid dimensions, not just base island
  if world and worldWidth and worldHeight and tileSize then
    return {
      width = worldWidth,     -- Full world grid width (e.g., 112 tiles)
      height = worldHeight,   -- Full world grid height (e.g., 82 tiles)
      tileSize = tileSize,    -- Tile size in pixels (32)
      collisionGrid = world   -- Full world pathfinding grid
    }
  end
  return nil
end

-- Add a new monster at the specified position
-- x, y should be the desired PathfindingCollision center position
function GameScene.addMonster(x, y, type)

  if not ecsWorld or not physicsWorld then
    return nil
  end

  local EntityUtils = require("src.utils.entities")
  local monster = EntityUtils.spawnMonster(x, y, type, ecsWorld, physicsWorld)

  if monster then
    table.insert(monsters, monster)
    print("Added", type, "at:", x, y, "Total monsters:", #monsters)
  end

  return monster
end

-- Handle mouse press
function GameScene.mousepressed(x, y, button, gameState)
  -- First check if UI systems can handle the press
  if uiWorld then
    for _, system in ipairs(uiWorld.systems) do
      if system.handleMousePressed then
        local handled = system:handleMousePressed(x, y, button)
        if handled then
          return true -- UI system handled the press, don't process further
        end
      end
    end
  end

  -- If not handled by UI systems, process game logic
  if button == 2 then -- Right click
    print("Right click at:", x, y)
    -- Add a monster at click position (convert screen to world coordinates)
    local CoordinateUtils = require("src.utils.coordinates")
    local worldX, worldY = CoordinateUtils.screenToWorld(x, y, gameState.camera)
    GameScene.addMonster(worldX, worldY, "warhog")
  end

  -- Click was not handled by UI
  return false
end

-- Handle mouse release
function GameScene.mousereleased(x, y, button, gameState)
  -- Check if UI systems can handle the release
  if uiWorld then
    for _, system in ipairs(uiWorld.systems) do
      if system.handleMouseReleased then
        local handled = system:handleMouseReleased(x, y, button)
        if handled then
          return -- UI system handled the release, don't process further
        end
      end
    end
  end
end

-- Handle keyboard input for UI systems
function GameScene.handleKeyPressed(key, gameState)
  -- Check if UI systems can handle the key press
  if uiWorld then
    for _, system in ipairs(uiWorld.systems) do
      if system.handleKeyPress then
        local handled = system:handleKeyPress(key)
        if handled then
          return true -- UI system handled the key, don't process further
        end
      end
    end
  end
  return false
end

-- Draw world content only (no UI) - for postprocessing pipeline
function GameScene.drawWorld(gameState)
  -- Apply camera transform for world rendering
  gameState.camera:draw(function()
    -- Draw simple world using MapManager
    MapManager.draw(gameState.camera)

    -- Draw ECS entities (world-space systems only)
    if ecsWorld then
      ecsWorld:drawWorldSpace()
    end

    -- Draw world-space UI elements (health bars) inside camera transform
    if uiWorld then
      for _, system in ipairs(uiWorld.systems) do
        if system.isWorldSpace then
          system:draw()
        end
      end
    end
  end)
end

-- Draw UI elements only
function GameScene.drawUI(gameState)
  if uiWorld then
    -- Draw screen-space UI elements (HUD, menus) outside camera transform
    -- Use uiWorld:draw() which respects drawOrder for z-layering
    love.graphics.push()
    love.graphics.origin()

    -- Build sorted list of screen-space systems
    local screenSpaceSystems = {}
    for _, system in ipairs(uiWorld.systems) do
      if not system.isWorldSpace then
        table.insert(screenSpaceSystems, system)
      end
    end

    -- Sort by drawOrder if uiWorld has it enabled
    if uiWorld.useDrawOrder then
      table.sort(screenSpaceSystems, function(a, b)
        local orderA = a.drawOrder or 0
        local orderB = b.drawOrder or 0
        return orderA < orderB
      end)
    end

    -- Draw in sorted order
    for _, system in ipairs(screenSpaceSystems) do
      system:draw()
    end

    love.graphics.pop()
  end

  -- Draw screen-space ECS systems (e.g., aim line)
  if ecsWorld then
    love.graphics.push()
    love.graphics.origin()
    for _, system in ipairs(ecsWorld.systems) do
      if system.isWorldSpace == false and system ~= GameScene.aimLineSystem then
        system:draw()
      end
    end
    love.graphics.pop()
  end
end

function GameScene.drawAimLine(gameState)
  if not GameScene.aimLineSystem then
    return
  end

  -- Ensure the system has world reference
  if not GameScene.aimLineSystem.world and ecsWorld then
    GameScene.aimLineSystem:setWorld(ecsWorld)
  end

  love.graphics.push()
  love.graphics.origin()
  GameScene.aimLineSystem:draw()
  love.graphics.pop()
end

-- Draw everything (for backward compatibility)
function GameScene.draw(gameState)
  GameScene.drawWorld(gameState)
  GameScene.drawUI(gameState)
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

  -- Unload all maps
  MapManager.unload()

  -- Clear entity references and flags
  playerEntity = nil
  mouseFacingSystemAdded = false
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
