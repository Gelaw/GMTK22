map =nil-- stores tiledata
mapWidth, mapHeight = nil-- width and height in tiles

mapI, mapJ =nil-- view i,j. can be a fractional value like 3.25.
mapX, mapY = nil--position of the map display on the screen
tilesDisplayWidth, tilesDisplayHeight =nil-- number of tiles to show
zoomX, zoomY =nil

local tilesetImage
tileSize =64 -- size of tiles in pixels in the tileSet
local tileQuads = {} -- parts of the tileset used for different tiles
local tilesetSprite
idMap = 2

function setupMap()

  handmademap = maps[idMap]
  if handmademap and #handmademap >0 then
    mapWidth = #handmademap[1]
    mapHeight = #handmademap
    map = {}
    print(mapWidth, mapHeight)
    for x=1, mapWidth do
      map[x] = {}
      for y=1,mapHeight do
        map[x][y] = handmademap[y][x]
      end
    end
  else
    mapWidth = 15
    mapHeight = 15
    map = {}
    for x=1,mapWidth do
      map[x] = {}
      for y=1,mapHeight do
        map[x][y] = 0
      end
    end
  end
  if idMap == 2 then
    -- volcano = applyParams(newEntity(), {x=math.random(50)-width/2, h=math.random(-100, 100), w=258, h=258, spriteSet = {path = "src/img/sprites/VolcanoTile.png", width = 258, height = 258, duration = 2.3}})
    -- animation = newAnimation(love.graphics.newImage("src/img/sprites/VolcanoTile.png"), 258, 258, 2.3, 258, 258)
    -- volcano:initEntity()
  end
end

function fillMap()
  -- cx, cy = math.random(mapWidth), math.random(mapHeight)
  -- size = 3
  -- for x=cx-size, cx+size do
  --   for y=cy-size, cy+size do
  --     if map[x] and map[x][y] then
  --       map[x][y] = 1
  --     end
  --   end
  -- end

  updateTilesetBatch()
end

function setupMapView()
  mapI = 1
  mapJ = 1
  zoomX = 1
  zoomY = 1.4/2
  tileSize = 64

  tilesDisplayWidth = width/(tileSize * zoomX) + 1
  tilesDisplayHeight = height/(tileSize * zoomY) + 1

  mapX, mapY = .5*(width - mapWidth*tileSize*zoomX), .3*(height - mapHeight*tileSize*zoomY)
  addDrawFunction(function ()
    drawMap()
  end, 4)
end

mapHidden = true

function drawMap()
  if mapHidden then return end
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

function newQuad(i, j)
  return love.graphics.newQuad(i * tileSize,  j* tileSize, tileSize, tileSize,
  tilesetImage:getWidth(), tilesetImage:getHeight())
end

function setupTileset()
  tilesetImage = love.graphics.newImage( "src/img/sprites/TileFusion.png" )
  tilesetImage:setFilter("nearest", "linear") -- this "linear filter" removes some artifacts if we were to scale the tiles
 
  for i = 0, tilesetImage:getWidth()/tileSize do
    tileQuads[i] = newQuad(i, idMap-1)
  end

  
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