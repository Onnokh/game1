return {
  {
      time = 200, -- start after 10 seconds
      duration = 100,
      enemies = {
          { type = "Skeleton", count = 2 },
      },
      spawnRate = 5.0,
      shape = {
          type = "circle",
          radius = 150
      }
  },
  {
      time = 305,
      duration = 9999, -- endless scaling after this
      enemies = {
          { type = "Slime", count = 4 },
      },
      spawnRate = 5.0,
      shape = {
          type = "circle",
          radius = 200
      }
  },
}
