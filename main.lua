require "base"
require "ui"
require "map"
require "entity"

function projectSetup()
  love.graphics.setBackgroundColor(.3, .3, .3)

  setupMap()
  setupMapView()
  setupTileset()

  player = newEntity({i = 30, j=30, w=32, h=32, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
  player:loadAnimation()

  addDrawFunction(function ()
    love.graphics.origin()
    local x, y = love.mouse.getX(), love.mouse.getY()
    love.graphics.print(x.." "..y)
    local i, j = screenToGrid(x, y)
    love.graphics.print(i.." "..j, 0, 15)
  end)
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    player.i, player.j = screenToGrid(x, y) 
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
    love.graphics.setColor(1, 1, 1)
    local spriteNum = math.floor(self.currentTime / self.duration * #self.quads) + 1
    love.graphics.draw(self.spriteSheet, self.quads[spriteNum], -.5*width*self.scale.x, -.5*height*self.scale.y, 0, self.scale.x, self.scale.y)
  end
  return animation
end