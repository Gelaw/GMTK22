map =nil-- stores tiledata
mapWidth, mapHeight = nil-- width and height in tiles

mapI, mapJ =nil-- view i,j. can be a fractional value like 3.25.
mapX, mapY = nil--position of the map display on the screen
tilesDisplayWidth, tilesDisplayHeight =nil-- number of tiles to show
zoomX, zoomY =nil

local tilesetImage
tileSize =16 -- size of tiles in pixels in the tileSet
local tileQuads = {} -- parts of the tileset used for different tiles
local tilesetSprite

function setupMap()
  mapWidth = 15
  mapHeight = 15
  map = {}
  for x=1,mapWidth do
    map[x] = {}
    for y=1,mapHeight do
      map[x][y] = math.random(0, 3)
    end
  end
end

function setupMapView()
  mapI = 1
  mapJ = 1
  zoomX = 2*2
  zoomY = 1.41*2
  tileSize = 16

  tilesDisplayWidth = width/(tileSize * zoomX) + 1
  tilesDisplayHeight = height/(tileSize * zoomY) + 1

  mapX, mapY = .5*(width - mapWidth*tileSize*zoomX), .3*(height - mapHeight*tileSize*zoomY)
  addDrawFunction(function ()
    drawMap()
  end, 4)
end

function drawMap()
  love.graphics.origin()
  love.graphics.setColor(1, 1, 1)
  love.graphics.translate(mapX, mapY)
  local dx, dy = math.floor(-zoomX*(mapI%1)*tileSize), math.floor(-zoomY*(mapJ%1)*tileSize)
  love.graphics.draw(tilesetBatch, dx, dy, 0, zoomX, zoomY)
  -- love.graphics.print("FPS: "..love.timer.getFPS().."\tx:"..math.floor(mapI).."\ty:"..math.floor(mapJ), 10, 20)
  love.graphics.setColor(.3, .3, .3, .1)
  for i=0, tilesDisplayWidth-1 do
    for j=0, tilesDisplayHeight-1 do
      love.graphics.rectangle("line", i*zoomX*tileSize, j*zoomY*tileSize, zoomX*tileSize, zoomY*tileSize)
    end
  end
end

function setupTileset()
  tilesetImage = love.graphics.newImage( "sprite/Tiles.png" )
  tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles

  -- ground
  tileQuads[3] = love.graphics.newQuad(4 * tileSize, 6 * tileSize+10, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- deep ground
  tileQuads[1] = love.graphics.newQuad(32, 107, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- sky
  tileQuads[2] = love.graphics.newQuad(73, 106, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  -- cloud
  tileQuads[0] = love.graphics.newQuad(12 * tileSize, 3 * tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
  
  tilesetBatch = love.graphics.newSpriteBatch(tilesetImage, tilesDisplayWidth * tilesDisplayHeight)
  
  updateTilesetBatch()
end

function updateTilesetBatch()
  tilesetBatch:clear()
  for i=0, tilesDisplayWidth-1 do
    for j=0, tilesDisplayHeight-1 do
      if map[i+math.floor(mapI)] and map[i+math.floor(mapI)][j+math.floor(mapJ)] then
        tilesetBatch:add(tileQuads[map[i+math.floor(mapI)][j+math.floor(mapJ)]], i*tileSize, j*tileSize)
      end
    end
  end
  tilesetBatch:flush()
end

-- central function for moving the map
function moveMap(newX, newY)
  oldMapI = mapI
  oldMapJ = mapJ
  mapI = newX/(tileSize*zoomX)
  mapJ = newY/(tileSize*zoomY)
  -- only update if we actually moved
  if math.floor(mapI) ~= math.floor(oldMapI) or math.floor(mapJ) ~= math.floor(oldMapJ) then
    updateTilesetBatch()
  end
end

-- conversion between gridspace and screenspace
function screenToGrid(x, y)
  return math.floor((x-mapX)/(tileSize*zoomX)-mapI +2), math.floor((y-mapY)/(tileSize*zoomY) -mapJ +2)
end

function gridToScreen(i, j)
  return (mapI + i-2)*tileSize*zoomX-.5*width+mapX, (mapJ + j-2)*tileSize*zoomY-.5*height+mapY
end