return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.11.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 25,
  height = 25,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 9,
  nextobjectid = 37,
  properties = {},
  tilesets = {
    {
      name = "TX Tileset Grass",
      firstgid = 1,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 8,
      image = "../../tileset/TX Tileset Grass.png",
      imagewidth = 256,
      imageheight = 256,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 64,
      tiles = {}
    },
    {
      name = "TX Tileset Wall",
      firstgid = 65,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 16,
      image = "../../tileset/TX Tileset Wall.png",
      imagewidth = 512,
      imageheight = 512,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 256,
      tiles = {}
    },
    {
      name = "Objects",
      firstgid = 321,
      class = "",
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      columns = 0,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 1,
      tiles = {
        {
          id = 1,
          image = "../../reactor/reactor-Sheet.png",
          x = 0,
          y = 0,
          width = 64,
          height = 64
        }
      }
    },
    {
      name = "test",
      firstgid = 323,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 15,
      image = "../../world.png",
      imagewidth = 480,
      imageheight = 480,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 225,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 25,
      height = 25,
      id = 1,
      name = "Tile Layer 1",
      class = "",
      visible = true,
      opacity = 0.99,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        372, 379, 379, 379, 379, 379, 379, 377, 379, 379, 379, 379, 379, 377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 374,
        379, 379, 377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 378, 379, 379, 379, 379, 379, 379, 379,
        376, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 376, 379, 379, 379, 379, 379, 379,
        377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 376, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 378, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 377, 377, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 376, 378, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 377, 377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        376, 379, 379, 376, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 376, 379, 379, 379, 379, 379, 377, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 378, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 378, 378, 379, 379, 379, 379,
        379, 379, 379, 377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 376, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379,
        379, 377, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 378, 379, 379, 379, 379, 379,
        379, 379, 379, 379, 378, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 379, 378, 379, 379, 379, 379, 379, 379,
        368, 328, 329, 328, 329, 327, 376, 377, 328, 327, 376, 329, 376, 328, 377, 377, 376, 327, 377, 376, 329, 378, 378, 376, 370,
        383, 343, 344, 343, 342, 343, 344, 342, 343, 344, 343, 342, 342, 343, 343, 344, 342, 342, 344, 344, 343, 342, 343, 342, 385
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 5,
      name = "Objects",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {
        {
          id = 23,
          name = "Spawn",
          type = "",
          shape = "point",
          x = 527.788,
          y = 274.925,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 35,
          name = "Reactor",
          type = "",
          shape = "rectangle",
          x = 352,
          y = 288,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
