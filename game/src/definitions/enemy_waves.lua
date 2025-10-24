return {
  {
      time = 100, -- start after 10 seconds
      duration = 30,
      enemies = {
          { type = "Warhog", count = 3 },
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
          { type = "Warhog", count = 5 },
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
          { type = "Warhog", count = 8 },
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
          { type = "Warhog", count = 10 },
          { type = "Warhog", count = 4 },
          { type = "Slime", count = 4 },
      },
      spawnRate = 5.0,
      shape = {
          type = "circle",
          radius = 200
      }
  },
}
