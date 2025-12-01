return {
  {
      time = 100, -- start after 10 seconds
      duration = 100,
      enemies = {
          { type = "cragboar", count = 2 },
          { type = "bear", count = 1 },
      },
      spawnRate = 1.0,
      shape = {
          type = "circle",
          radius = 150
      }
  },
  -- {
  --     time = 305,
  --     duration = 9999, -- endless scaling after this
  --     enemies = {
  --         { type = "Slime", count = 4 },
  --     },
  --     spawnRate = 5.0,
  --     shape = {
  --         type = "circle",
  --         radius = 200
  --     }
  -- },
}
