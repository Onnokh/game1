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
        85, 211, 167, 213, 214, 87, 164, 167, 165, 164, 165, 165, 167, 165, 164, 165, 164, 167, 87, 164, 165, 164, 167, 165, 89,
        101, 227, 183, 229, 230, 103, 180, 183, 181, 180, 181, 181, 183, 181, 180, 181, 180, 183, 103, 180, 181, 181, 183, 181, 105,
        117, 28, 18, 9, 30, 4, 2, 23, 7, 11, 27, 16, 30, 12, 14, 18, 14, 11, 32, 2, 11, 23, 2, 2, 105,
        85, 27, 18, 5, 9, 28, 27, 13, 26, 7, 17, 30, 27, 23, 7, 10, 25, 18, 17, 10, 4, 14, 30, 18, 121,
        101, 30, 2, 9, 17, 12, 5, 17, 3, 26, 14, 32, 3, 4, 16, 32, 12, 13, 19, 17, 10, 18, 12, 18, 105,
        85, 23, 16, 32, 20, 1, 27, 10, 17, 19, 18, 34, 34, 20, 10, 2, 27, 3, 25, 25, 25, 23, 17, 30, 121,
        101, 16, 11, 7, 7, 10, 2, 20, 2, 33, 34, 42, 13, 42, 42, 3, 26, 20, 10, 2, 20, 1, 32, 9, 105,
        117, 10, 23, 26, 14, 1, 17, 2, 33, 34, 34, 33, 34, 41, 41, 42, 14, 26, 25, 30, 32, 10, 11, 28, 105,
        85, 19, 26, 27, 25, 1, 12, 7, 19, 34, 42, 33, 33, 41, 25, 4, 19, 2, 20, 3, 14, 9, 5, 30, 121,
        101, 11, 20, 3, 23, 12, 13, 26, 32, 22, 34, 41, 33, 41, 42, 42, 2, 16, 19, 3, 3, 3, 28, 12, 105,
        117, 27, 4, 5, 32, 25, 5, 14, 24, 34, 34, 4, 34, 34, 13, 1, 25, 25, 30, 3, 3, 3, 5, 30, 105,
        85, 25, 10, 16, 20, 11, 12, 18, 29, 19, 28, 28, 20, 18, 12, 22, 7, 5, 2, 14, 3, 23, 11, 4, 105,
        101, 14, 26, 11, 26, 7, 16, 11, 27, 14, 19, 30, 13, 2, 30, 14, 26, 1, 14, 16, 14, 5, 17, 2, 105,
        117, 7, 3, 11, 5, 19, 1, 14, 23, 5, 26, 19, 3, 5, 14, 20, 30, 18, 3, 12, 23, 32, 28, 2, 105,
        101, 11, 4, 1, 18, 29, 17, 20, 24, 13, 12, 24, 26, 18, 20, 20, 20, 24, 6, 12, 1, 18, 15, 3, 105,
        117, 6, 28, 2, 18, 4, 13, 28, 6, 26, 27, 12, 32, 3, 28, 10, 20, 12, 18, 1, 2, 10, 13, 1, 105,
        101, 19, 28, 19, 9, 16, 30, 32, 23, 27, 11, 17, 23, 13, 25, 20, 32, 18, 23, 17, 13, 12, 11, 19, 105,
        117, 37, 38, 39, 40, 37, 38, 39, 40, 37, 38, 39, 40, 37, 38, 39, 40, 37, 38, 39, 40, 40, 37, 38, 105,
        101, 45, 46, 47, 48, 45, 46, 47, 48, 45, 46, 47, 48, 45, 46, 47, 48, 45, 46, 47, 48, 48, 45, 46, 105,
        117, 3, 11, 26, 17, 2, 28, 5, 4, 18, 3, 1, 27, 3, 9, 13, 4, 23, 28, 11, 3, 30, 17, 2, 105,
        101, 16, 1, 11, 14, 11, 27, 25, 25, 11, 16, 26, 25, 19, 13, 16, 13, 19, 23, 27, 25, 28, 28, 1, 105,
        117, 30, 2, 10, 17, 5, 27, 16, 12, 19, 28, 18, 4, 30, 26, 1, 12, 4, 10, 19, 13, 16, 5, 14, 105,
        101, 10, 2, 11, 28, 12, 14, 25, 18, 28, 1, 5, 9, 1, 1, 9, 30, 5, 1, 18, 18, 2, 11, 16, 105,
        117, 30, 25, 23, 16, 17, 28, 2, 3, 30, 28, 32, 19, 9, 1, 19, 5, 3, 26, 20, 17, 2, 11, 12, 121,
        133, 134, 135, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 136, 137
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
          x = 496.848,
          y = 245.33,
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
          x = 576,
          y = 288,
          width = 64,
          height = 64,
          rotation = 0,
          gid = 322,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
