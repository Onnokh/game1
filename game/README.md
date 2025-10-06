# Game Project Structure

## Directory Structure

```
game/
├── conf.lua                    -- Love2D engine configuration (window size, title, etc.)
├── main.lua                    -- Game entry point, initializes Love2D callbacks and starts first scene
├── product.env                 -- Build and deployment environment variables
├── GAMELOOP.md                 -- Documentation explaining the game's update/render loop architecture
├── lovebird.lua               -- Debug console overlay for runtime inspection and testing
│
├── lib/                       -- External libraries and frameworks
│   ├── gamera.lua             -- 2D camera system for viewport management and smooth following
│   ├── iffy.lua               -- Configuration file parser for game settings and data files
│   ├── jumper/                -- A* pathfinding library for AI navigation and movement
│   └── overlayStats.lua       -- Performance profiler displaying FPS, memory usage, and frame timing
│
├── runtime/                   -- Platform-specific native libraries and dependencies
│   └── https/                 -- HTTPS client library binaries for different operating systems
│
├── shadows/                   -- Dynamic shadow rendering system for atmospheric lighting
│   ├── Room/                  -- Room-based shadow casting (circles, rectangles, polygons)
│   └── ShadowShapes/          -- Individual shadow shape implementations (normal, height, image)
│
├── resources/                 -- Game assets and media files
│   ├── character/             -- Player character sprites, animations, and sprite sheets
│   ├── font/                  -- Custom fonts for UI text rendering
│   ├── reactor/               -- Reactor entity graphics and animation frames
│   ├── skeleton/              -- Skeleton enemy sprites and visual assets
│   └── tileset/               -- Tile graphics for world map rendering (grass, water, paths, cliffs)
│
└── src/                       -- Core game source code
    ├── components/            -- ECS data components (Position, Health, Movement, Collision, etc.)
    ├── core/                  -- Entity-Component-System framework (Entity, World, System base classes)
    ├── entities/              -- Game object definitions and configurations
    │   ├── Monsters/          -- Enemy entity implementations with AI states and behaviors
    │   └── Player/            -- Player entity with movement states and input handling
    ├── scenes/                -- Game state management (menu screens, gameplay, transitions)
    ├── shaders/               -- GLSL shaders for visual effects (damage numbers, flash effects)
    ├── systems/               -- ECS logic systems that process components and update entities
    │   └── UISystems/         -- User interface systems (health bars, damage popups, HUD)
    ├── ui/                    -- UI element classes and layout components
    └── utils/                 -- Helper functions (coordinate conversion, input handling, font management)
```
