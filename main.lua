require "base"
require "ui"
require "map"
require "entity"
require "action"

function projectSetup()
  love.graphics.setBackgroundColor(.3, .3, .3)

  setupMap()
  setupMapView()
  setupTileset()

  player = applyParams(newEntity(), {i = 7, j=7, w=32, h=32, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
  player:initEntity()

  addDrawFunction(function ()
    love.graphics.origin()
    local x, y = love.mouse.getX(), love.mouse.getY()
    love.graphics.print(x.." "..y)
    local i, j = screenToGrid(x, y)
    love.graphics.print(i.." "..j, 0, 15)
  end)
  testActions()
  testLivingEntityRessource()
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    local i, j = screenToGrid(x, y)
    if map[i] and map[i][j] then
      player.i, player.j = i, j
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
  --https://www.youtube.com/watch?v=79DijItQXMM
  if key == "escape" then
    love.event.quit()
    print("...")
  end
end

function newAnimation(image, width, height, duration, w, h)
  local animation = {}
  animation.spriteSheet = image;
  animation.quads = {};
  animation.scale = {x = w/width, y = h/height} or {x=1, y=1}
  for y = 0, image:getHeight() - height, height do
    for x = 0, image:getWidth() - width, width do
      table.insert(animation.quads, love.graphics.newQuad(x, y, width, height, image:getDimensions()))
    end
  end

  animation.duration = duration or 1
  animation.currentTime = 0

  animation.update = function (self, dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.duration then
      self.currentTime = self.currentTime - self.duration
    end
  end

  animation.draw = function (self)
    local spriteNum = math.floor(self.currentTime / self.duration * #self.quads) + 1
    love.graphics.draw(self.spriteSheet, self.quads[spriteNum], -.5*width*self.scale.x, -.5*height*self.scale.y, 0, self.scale.x, self.scale.y)
  end
  return animation
end

function getEntityOn(i, j)
  for e, entity in pairs(entities) do
    if entity.i and entity.i == i and entity.j and entity.j == j then return entity end
  end
end
