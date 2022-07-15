require "base"
require "ui"
require "map"

function projectSetup()
  love.graphics.setBackgroundColor(.3, .3, .3)

  setupMap()
  setupMapView()
  setupTileset()

  player = newEntity({x = 70*16, y=70*16, w=32, h=64, spriteSet = "sprite/oldHero.png"})
  camera.mode = {"follow", player}
end

function love.mousepressed(x, y, button, isTouch)
  UIMousePress(x, y , button)
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

function newEntity(params)
  local entity = applyParams({}, params)
  if entity.spriteSet then
    entity.animation = newAnimation(love.graphics.newImage(entity.spriteSet), 16, 18, 1)
  end
  if entity.animation then
    entity.draw = function (self)
      love.graphics.setColor(1, 1, 1)
      love.graphics.translate(self.x-.5*self.w, self.y-.5*self.h)
      self.animation:draw()
    end
    entity.update = function (self, dt)
      if love.keyboard.isDown("up") or love.keyboard.isDown("z") then
        self.y = self.y - 10
      end
      if love.keyboard.isDown("down") or love.keyboard.isDown("s")  then
        self.y = self.y + 10
      end
      if love.keyboard.isDown("left") or love.keyboard.isDown("q")  then
        self.x = self.x - 10
      end
      if love.keyboard.isDown("right") or love.keyboard.isDown("d")  then
        self.x = self.x + 10
      end
      self.animation:update(dt)
    end
  else
    entity.color = entity.color or {.8, 0, .8}
    entity.draw = function (self)
      love.graphics.translate(self.x-.5*self.w, self.y-.5*self.h)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end
    entity.update = function (self, dt)
      if love.keyboard.isDown("up") or love.keyboard.isDown("z") then
        self.y = self.y - 10
      end
      if love.keyboard.isDown("down") or love.keyboard.isDown("s")  then
        self.y = self.y + 10
      end
      if love.keyboard.isDown("left") or love.keyboard.isDown("q")  then
        self.x = self.x - 10
      end
      if love.keyboard.isDown("right") or love.keyboard.isDown("d")  then
        self.x = self.x + 10
      end
    end
  end
  table.insert(entities, entity)
  return entity
end

function newAnimation(image, width, height, duration, x, y)
  local animation = {}
  animation.spriteSheet = image;
  animation.quads = {};
  animation.x, animation.y = 0, 0
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
    love.graphics.draw(self.spriteSheet, self.quads[spriteNum], self.x, self.y, 0, 4)
  end
  return animation
end