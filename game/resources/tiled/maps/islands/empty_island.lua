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
  nextobjectid = 70,
  properties = {},
  tilesets = {
    {
      name = "Objects",
      firstgid = 1,
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
    },
    {
      name = "test",
      firstgid = 4,
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
      name = "tiland",
      firstgid = 229,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 26,
      image = "../../../tiland.png",
      imagewidth = 832,
      imageheight = 675,
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
      tilecount = 546,
      tiles = {}
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
        0, 0, 465, 466, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 0, 0,
        0, 0, 491, 492, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 0, 0,
        0, 0, 595, 596, 518, 597, 598, 599, 600, 523, 524, 525, 526, 527, 528, 529, 530, 531, 0, 0,
        0, 0, 621, 622, 544, 597, 598, 599, 600, 549, 550, 551, 552, 553, 554, 555, 556, 557, 0, 0,
        0, 0, 647, 648, 570, 623, 624, 625, 626, 575, 576, 577, 578, 579, 580, 581, 582, 583, 0, 0,
        0, 0, 673, 674, 674, 675, 676, 677, 678, 679, 680, 681, 682, 683, 684, 685, 686, 687, 0, 0,
        0, 0, 699, 700, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 0, 0,
        0, 0, 725, 726, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 0, 0,
        0, 0, 725, 726, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
          id = 69,
          name = "MobSpawn",
          type = "",
          shape = "rectangle",
          x = 160,
          y = 96,
          width = 65,
          height = 97.5,
          rotation = 0,
          visible = true,
          properties = {
            ["amount"] = 2
          }
        }
      }
    }
  }
}
