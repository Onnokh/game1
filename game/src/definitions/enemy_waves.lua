return {
  {
      time = 100, -- start after 10 seconds
      duration = 30,
      enemies = {
          { type = "Skeleton", count = 3 },
      },
      spawnRate = 1.0,
      shape = {
          type = "circle",
          radius = 150
      }
  },
  {
      time = 30,
      duration = 30,
      enemies = {
          { type = "Skeleton", count = 2 },
      },
      spawnRate = 1.0,
      shape = {
          type = "line",
          length = 100,
          distance = 100
      }
  },
  {
      time = 60,
      duration = 45,
      enemies = {
          { type = "Slime", count = 2 },
      },
      spawnRate = 1.2,
      shape = {
        type = "circle",
        radius = 200
      }
  },
  {
      time = 105,
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
