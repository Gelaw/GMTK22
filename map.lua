local map -- stores tiledata
local mapWidth, mapHeight -- width and height in tiles

local mapX, mapY -- view x,y in tiles. can be a fractional value like 3.25.

local tilesDisplayWidth, tilesDisplayHeight -- number of tiles to show
local zoomX, zoomY

local tilesetImage
local tileSize -- size of tiles in pixels
local tileQuads = {} -- parts of the tileset used for different tiles
local tilesetSprite

function setupMap()
  mapWidth = 100
  mapHeight = 100
  map = {}
  for x=1,mapWidth do
    map[x] = {}
    for y=1,mapHeight do
      if y == math.floor(.7 * mapHeight) then
        map[x][y] = 0
      elseif y > math.floor(.7 * mapHeight) then
        map[x][y] = 1
      else
        map[x][y] = math.random(2, 3)
      end
    end
  end
  addUpdateFunction(function (dt)
    moveMap(camera.x, camera.y)
  end)
end

function setupMapView()
  mapX = 1
  mapY = 1
  tilesDisplayWidth = width/32 + 1
  tilesDisplayHeight = height/32 + 1
  
  zoomX = 2
  zoomY = 2
  addDrawFunction(function ()
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1)
    local dx, dy = math.floor(-zoomX*(mapX%1)*tileSize), math.floor(-zoomY*(mapY%1)*tileSize)
    love.graphics.draw(tilesetBatch, dx, dy, 0, zoomX, zoomY)
    love.graphics.print("FPS: "..love.timer.getFPS().."\tx:"..math.floor(mapX).."\ty:"..math.floor(mapY), 10, 20)
  end, 4)
end

function setupTileset()
  tilesetImage = love.graphics.newImage( "sprite/Tiles.png" )
  tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
  tileSize = 16
  
  -- ground
  tileQuads[0] = love.graphics.newQuad(11 * tileSize, 6 * tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- deep ground
  tileQuads[1] = love.graphics.newQuad(11 * tileSize, 7 * tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- sky
  tileQuads[2] = love.graphics.newQuad(0 * tileSize, 2 * tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- cloud
  tileQuads[3] = love.graphics.newQuad(12 * tileSize, 3 * tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  
  tilesetBatch = love.graphics.newSpriteBatch(tilesetImage, tilesDisplayWidth * tilesDisplayHeight)
  
  updateTilesetBatch()
end

function updateTilesetBatch()
  tilesetBatch:clear()
  for x=0, tilesDisplayWidth-1 do
    for y=0, tilesDisplayHeight-1 do
      if map[x+math.floor(mapX)] and map[x+math.floor(mapX)][y+math.floor(mapY)] then
        tilesetBatch:add(tileQuads[map[x+math.floor(mapX)][y+math.floor(mapY)]], x*tileSize, y*tileSize)
      end
    end
  end
  tilesetBatch:flush()
end

-- central function for moving the map
function moveMap(newX, newY)
  oldMapX = mapX
  oldMapY = mapY
  mapX = newX/32
  mapY = newY/32
  -- only update if we actually moved
  if math.floor(mapX) ~= math.floor(oldMapX) or math.floor(mapY) ~= math.floor(oldMapY) then
    updateTilesetBatch()
  end
end