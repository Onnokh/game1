return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.11.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 20,
  height = 10,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 5,
  nextobjectid = 72,
  properties = {},
  tilesets = {
    {
      name = "test",
      firstgid = 1,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 15,
      image = "../../../world.png",
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
    },
    {
      name = "Objects",
      firstgid = 226,
      class = "",
      tilewidth = 96,
      tileheight = 96,
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
      tilecount = 2,
      tiles = {
        {
          id = 1,
          image = "../../../reactor/reactor-Sheet.png",
          width = 96,
          height = 96
        },
        {
          id = 2,
          image = "../../../objects/tree.png",
          width = 48,
          height = 96
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 20,
      height = 10,
      id = 1,
      name = "Tile Layer 1",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 121, 124, 122, 124, 122, 124, 122, 124, 124, 124, 122, 124, 122, 125, 0, 0, 0,
        0, 0, 0, 136, 137, 138, 139, 137, 137, 137, 138, 137, 138, 139, 139, 139, 140, 0, 0, 0,
        0, 0, 0, 136, 137, 138, 139, 137, 138, 137, 138, 137, 137, 137, 138, 139, 140, 0, 0, 0,
        0, 0, 0, 136, 137, 138, 139, 137, 138, 137, 138, 137, 138, 138, 138, 138, 140, 0, 0, 0,
        0, 0, 0, 136, 137, 138, 139, 137, 138, 137, 137, 138, 138, 138, 138, 138, 140, 0, 0, 0,
        0, 0, 0, 136, 137, 137, 137, 137, 138, 139, 137, 137, 138, 138, 138, 138, 140, 0, 0, 0,
        0, 0, 0, 151, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 154, 155, 0, 0, 0,
        0, 0, 0, 166, 167, 167, 167, 167, 167, 167, 167, 167, 167, 167, 167, 169, 170, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
      name = "Objects",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {}
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 2,
      name = "Area",
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
          id = 71,
          name = "Shop",
          type = "",
          shape = "rectangle",
          x = 288,
          y = 96,
          width = 64,
          height = 64,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
