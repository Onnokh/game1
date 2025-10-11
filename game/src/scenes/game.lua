---@class GameScene
local GameScene = {}

-- Scene state
local world = {} -- For pathfinding and collision detection
local GameConstants = require("src.constants")
local sprites = require("src.utils.sprites")
local WorldLight = require("src.utils.worldlight")
local MapManager = require("src.maps.MapManager")
local TiledMapLoader = require("src.utils.TiledMapLoader")
local GameState = require("src.core.GameState")

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
local BulletSystem = require("src.systems.BulletSystem")
local WeaponSystem = require("src.systems.WeaponSystem")
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
local AimLineRenderSystem = require("src.systems.AimLineRenderSystem")
local ShaderManager = require("src.utils.ShaderManager")
local Player = require("src.entities.Player.Player")
local Reactor = require("src.entities.Reactor.Reactor")
local Tree = require("src.entities.Decoration.Tree")
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
  ecsWorld:addSystem(WeaponSystem.new()) -- Handle weapon switching and syncing
  ecsWorld:addSystem(AttackSystem.new()) -- Handle attacks
  ecsWorld:addSystem(BulletSystem.new()) -- Handle bullet movement and collision
  ecsWorld:addSystem(AttackColliderSystem.new()) -- Manage ephemeral attack colliders
  ecsWorld:addSystem(DamageSystem.new()) -- Process damage events (includes knockback)
  ecsWorld:addSystem(LootSystem.new()) -- Handle loot drops when entities die
  ecsWorld:addSystem(CoinPickupSystem.new()) -- Handle coin pickup collisions
  ecsWorld:addSystem(CoinAttractionSystem.new()) -- Handle coin attraction to player
  ecsWorld:addSystem(OxygenSystem.new()) -- Handle oxygen decay when outside reactor zone
  ecsWorld:addSystem(InteractionSystem.new()) -- Handle interactions with interactable entities
  ecsWorld:addSystem(FlashEffectSystem.new()) -- Update flash effects
  ecsWorld:addSystem(AnimationSystem.new()) -- Advance animations
  ecsWorld:addSystem(ShadowSystem.new()) -- Update shadow bodies
  ecsWorld:addSystem(LightSystem.new()) -- Manage dynamic lights
  ecsWorld:addSystem(GroundShadowSystem.new()) -- Draw ground shadows beneath sprites
  ecsWorld:addSystem(RenderSystem.new()) -- Render sprites and debug visuals
  ecsWorld:addSystem(ParticleRenderSystem.new()) -- Render particles above sprites
  ecsWorld:addSystem(AimLineRenderSystem.new()) -- Draw aiming line for ranged weapons

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
  local AggroVignetteSystem = require("src.systems.UISystems.AggroVignetteSystem")
  local WeaponIndicatorSystem = require("src.systems.UISystems.WeaponIndicatorSystem")

  local healthBarSystem = HealthBarSystem.new(ecsWorld)
  uiWorld:addSystem(healthBarSystem)
  uiWorld:addSystem(HUDSystem.new(ecsWorld, healthBarSystem)) -- Pass healthBarSystem reference
  uiWorld:addSystem(WeaponIndicatorSystem.new(ecsWorld))
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
  uiWorld:addSystem(AggroVignetteSystem.new(ecsWorld)) -- Show vignette when mobs are chasing player

  -- Load multi-island world using MapManager
  local loadStart = love.timer.getTime()
  MapManager.load("src/maps/level1")
  print(string.format("[GameScene] MapManager.load took %.2fs", love.timer.getTime() - loadStart))

  -- Get base island for world setup
  local baseIsland = MapManager.getMap("base")
  if not baseIsland or not baseIsland.map then
    print("[GameScene] ERROR: Failed to load base island!")
    return
  end

  -- Calculate bounding box of ALL islands
  local minX, minY = 0, 0
  local maxX, maxY = baseIsland.width, baseIsland.height

  for _, island in ipairs(MapManager.getAllMaps()) do
    minX = math.min(minX, island.x)
    minY = math.min(minY, island.y)
    maxX = math.max(maxX, island.x + island.width)
    maxY = math.max(maxY, island.y + island.height)
  end

  -- Add padding
  local padding = 500
  minX = minX - padding
  minY = minY - padding
  maxX = maxX + padding
  maxY = maxY + padding

  -- Calculate offset to make everything positive and grid-aligned
  local offsetX = -minX
  local offsetY = -minY

  -- Snap offset to tile grid to keep islands aligned
  offsetX = math.ceil(offsetX / tileSize) * tileSize
  offsetY = math.ceil(offsetY / tileSize) * tileSize

  -- Adjust all island positions by the offset
  for _, island in ipairs(MapManager.getAllMaps()) do
    island.x = island.x + offsetX
    island.y = island.y + offsetY
  end

  -- Adjust all bridge positions by the offset
  for _, bridge in ipairs(MapManager.getBridges()) do
    bridge.x = bridge.x + offsetX
    bridge.y = bridge.y + offsetY
  end

  -- Calculate new camera bounds (now starting from 0,0)
  local camWidth = maxX - minX
  local camHeight = maxY - minY

  print(string.format("[GameScene] World offset: (%.0f, %.0f)", offsetX, offsetY))
  print(string.format("[GameScene] Camera bounds: (0, 0) to (%.0f, %.0f)", camWidth, camHeight))

  -- Use base island tile size
  tileSize = baseIsland.map.tilewidth

  -- Calculate world grid dimensions to encompass all islands
  worldWidth = math.ceil(camWidth / tileSize)
  worldHeight = math.ceil(camHeight / tileSize)

  local gridStart = love.timer.getTime()

  -- OPTIMIZATION: Pre-allocate grid with single walkable value
  world = {}
  local emptyTile = { walkable = false, type = 0 }
  for x = 1, worldWidth do
    world[x] = {}
    for y = 1, worldHeight do
      world[x][y] = emptyTile  -- Reuse same table for all empty tiles
    end
  end

  print(string.format("[GameScene] Pathfinding grid: %dx%d tiles (%.2fs)",
    worldWidth, worldHeight, love.timer.getTime() - gridStart))

  -- Add bridge tiles to pathfinding grid (make them walkable)
  local bridges = MapManager.getBridges()
  for _, bridge in ipairs(bridges) do
    if bridge.direction == "horizontal" then
      -- Vertical connection (horizontal bridge line)
      local bridgeX = math.floor(bridge.x / tileSize) + 1
      local bridgeStartY = math.floor(bridge.y / tileSize) + 1
      local bridgeEndY = math.floor((bridge.y + bridge.height) / tileSize)

      for tileY = bridgeStartY, bridgeEndY do
        if tileY >= 1 and tileY <= worldHeight and bridgeX >= 1 and bridgeX <= worldWidth then
          world[bridgeX][tileY] = {
            walkable = true,
            type = 1,
            gid = 140,  -- Bridge tile GID
            isBridge = true
          }
        end
      end
    elseif bridge.direction == "vertical" then
      -- Horizontal connection (vertical bridge line)
      local bridgeStartX = math.floor(bridge.x / tileSize) + 1
      local bridgeEndX = math.floor((bridge.x + bridge.width) / tileSize)
      local bridgeY = math.floor(bridge.y / tileSize) + 1

      for tileX = bridgeStartX, bridgeEndX do
        if tileX >= 1 and tileX <= worldWidth and bridgeY >= 1 and bridgeY <= worldHeight then
          world[tileX][bridgeY] = {
            walkable = true,
            type = 1,
            gid = 140,  -- Bridge tile GID
            isBridge = true
          }
        end
      end
    end
  end

  print(string.format("[GameScene] Added %d bridges to pathfinding grid", #bridges))

  -- Create collision bodies and mark walkable areas for each island
  local collisionStart = love.timer.getTime()
  local utilsTiledMapLoader = require("src.utils.TiledMapLoader")

  -- OPTIMIZATION: Cache collision grids by map path (don't reparse same map multiple times)
  local collisionGridCache = {}

  for _, island in ipairs(MapManager.getAllMaps()) do
    local islandMap = island.map
    local islandX = island.x
    local islandY = island.y
    local mapPath = island.definition.mapPath

    -- Check cache first
    local islandCollisionGrid = collisionGridCache[mapPath]
    if not islandCollisionGrid then
      -- Parse collision grid from this island's map data (only once per map type)
      islandCollisionGrid = utilsTiledMapLoader.parseCollisionGrid(
        islandMap,
        islandMap.width,
        islandMap.height
      )

      -- Debug: Count walkable tiles in parsed grid
      local parsedWalkableCount = 0
      for x = 1, islandMap.width do
        for y = 1, islandMap.height do
          if islandCollisionGrid[x] and islandCollisionGrid[x][y] and islandCollisionGrid[x][y].walkable then
            parsedWalkableCount = parsedWalkableCount + 1
          end
        end
      end
      print(string.format("  Parsed collision grid for '%s': %d walkable tiles out of %d total",
        island.definition.name, parsedWalkableCount, islandMap.width * islandMap.height))

      collisionGridCache[mapPath] = islandCollisionGrid
    end

    -- Mark walkable tiles in the global pathfinding grid
    -- OPTIMIZATION: Only create new table for walkable tiles
    local walkableTileCount = 0
    for localX = 1, islandMap.width do
      for localY = 1, islandMap.height do
        local tileData = islandCollisionGrid[localX][localY]

        -- Only process walkable tiles (skip empty/blocked)
        if tileData and tileData.walkable then
          -- Convert local island tile coords to global world tile coords
          local worldTileX = math.floor(islandX / tileSize) + localX
          local worldTileY = math.floor(islandY / tileSize) + localY

          if worldTileX >= 1 and worldTileX <= worldWidth and
             worldTileY >= 1 and worldTileY <= worldHeight then
            -- Create new table only for walkable tiles
            world[worldTileX][worldTileY] = {
              walkable = true,
              type = tileData.type,
              gid = tileData.gid
            }
            walkableTileCount = walkableTileCount + 1
          end
        end
      end
    end

    print(string.format("  Island '%s': %d walkable tiles marked (%.0f, %.0f)",
      island.definition.name, walkableTileCount, islandX, islandY))

    -- Create physics collision bodies for this island's tiles
    local islandColliders = utilsTiledMapLoader.createCollisionBodies(
      {
        collisionGrid = islandCollisionGrid,
        width = islandMap.width,
        height = islandMap.height,
        tileSize = tileSize
      },
      physicsWorld,
      islandX,  -- X offset
      islandY   -- Y offset
    )

    -- Add to border colliders list
    for _, collider in ipairs(islandColliders) do
      table.insert(borderColliders, collider)
    end
  end

  print(string.format("[GameScene] Collision setup took %.2fs", love.timer.getTime() - collisionStart))

  GameScene.borderColliders = borderColliders
  print(string.format("[GameScene] Total collision bodies: %d", #borderColliders))

  -- Store map data in GameState for debugging (overlay needs this)
  GameState.mapData = {
    width = worldWidth,
    height = worldHeight,
    tileSize = tileSize,
    collisionGrid = world
  }

  -- Spawn entities from ALL island maps
  local spawnStart = love.timer.getTime()

  for _, island in ipairs(MapManager.getAllMaps()) do
    local islandMap = island.map
    local islandX = island.x
    local islandY = island.y

    -- Parse objects from this island's map
    local objects = TiledMapLoader.parseObjects(islandMap)

    -- Spawn entities with offset for island position
    if objects.spawn and not playerEntity and island.id == "base" then
      -- Spawn player at base island spawn point
      playerEntity = Player.create(islandX + objects.spawn.x, islandY + objects.spawn.y, ecsWorld, physicsWorld)
    end

    -- Spawn reactors
    for _, obj in ipairs(objects.reactors or {}) do
      Reactor.create(islandX + obj.x, islandY + obj.y - obj.height, ecsWorld, physicsWorld)
    end

    -- Spawn other objects (trees, etc.)
    for _, obj in ipairs(objects.other or {}) do
      if obj.name == "Tree" then
        Tree.create(islandX + obj.x, islandY + obj.y - obj.height, ecsWorld, physicsWorld)
      end
    end
  end

  print(string.format("[GameScene] Entity spawning took %.2fs", love.timer.getTime() - spawnStart))

  -- If no spawn point found, spawn player at center of base island
  if not playerEntity then
    local centerX = baseIsland.x + baseIsland.width / 2
    local centerY = baseIsland.y + baseIsland.height / 2
    playerEntity = Player.create(centerX, centerY, ecsWorld, physicsWorld)
  end

  -- Create camera with positive-only bounds
  local gamera = require("lib.gamera")
  GameState.camera = gamera.new(0, 0, camWidth, camHeight)

  -- Center camera on player
  if playerEntity then
    local position = playerEntity:getComponent("Position")
    if position then
      GameState.camera:setPosition(position.x, position.y)
    end
  end

  GameState.camera:setScale(GameConstants.CAMERA_SCALE)

  print(string.format("[GameScene] Camera positioned at (%.2f, %.2f)", GameState.camera:getPosition()))

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

  local totalLoadTime = love.timer.getTime() - loadStart
  print(string.format("[GameScene] ===== TOTAL LOAD TIME: %.2fs =====", totalLoadTime))
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
    mouseFacingSystemAdded = true
  end

  -- Update all maps through MapManager (with camera culling)
  MapManager.update(dt, gameState.camera)

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
    local position = playerEntity:getComponent("Position")
    local collision = playerEntity:getComponent("Collision")
    local spriteRenderer = playerEntity:getComponent("SpriteRenderer")

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

-- Handle mouse press for debugging
function GameScene.mousepressed(x, y, button, gameState)
  -- First check if UI systems can handle the press
  if uiWorld then
    for _, system in ipairs(uiWorld.systems) do
      if system.handleMousePressed then
        local handled = system:handleMousePressed(x, y, button)
        if handled then
          return -- UI system handled the press, don't process further
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
    GameScene.addMonster(worldX, worldY, "slime")
  end
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

-- Draw the game scene
function GameScene.draw(gameState)
  -- Draw the world first
  gameState.camera:draw(function()
    -- Draw all islands using MapManager (with camera frustum culling)
    MapManager.draw(gameState.camera)

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
