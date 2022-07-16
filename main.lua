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

  player = applyParams(newLivingEntity(), {i = 7, j=7, w=32, h=32, spriteSet = {path = "sprite/oldHero.png", width = 16, height = 16}})
  player.ressources.life = newRessource("life", 10, 10)
  player:addAction(actions.Walk({range=2}))
  player:addAction(actions.MeleeAttack())
  player:addAction(actions.Heal())
  player:initEntity()

  game = {
    nTurn = 1,
    maxPrerolledTurns = 5,
    nextTurns = {"move", "move", "move", "move", "move"},
    fillTurns = function (self)
      while #self.nextTurns < self.maxPrerolledTurns do
        table.insert(self.nextTurns, actionTypesKeys[math.random(#actionTypesKeys)])
      end
    end,
    endTurn = function (self)
      table.remove(self.nextTurns, 1)
      self:fillTurns()
      game.nTurn = game.nTurn + 1
    end
  }


  setupUIs()
  --tests()
end


function setupUIs()
  uis = {}
  menuRadial = { -- Dedicace Sobroniel pour le nom de variable
    x = 0, y = height*.8,w=width, h = .2*height,
    color = {.1, .1, .1},
    children = {},
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end
  }
  table.insert(uis, menuRadial)
  
  playerActionsUIX = 400
  statsUI = {
    backgroundColor = {.5, .2, .2}, textColor = {.3, .7, .7},
    x = 10, y = 10, w = playerActionsUIX - 20, h = .2*height,
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      if player and player.ressources then
        love.graphics.print("life "..player.ressources.life.quantity.."/"..player.ressources.life.max)
      end
    end
  }
  table.insert(menuRadial.children, statsUI)

  playerActionsUI = {
    x = playerActionsUIX, y = 10,w=width-playerActionsUIX-170, h = .2*height-10,
    color = {.1, .1, .1},
    draw = function (self)
      love.graphics.setColor(self.color)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
    end,
    children = {},
    load = function (self)
      if not player or not player.actions then return end
      self.children = {}
      x = 10
      local child
      for a, action in pairs(player.actions) do
        child = {
          x = x, y = 10, w = 150, h = 150,
          draw = function (self)
            love.graphics.setColor(.2, .2, .2)
            love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(action.name, 5, 5)
            love.graphics.print(action.actionType, 135, 135)
            if action.actionType ~= game.nextTurns[1] then
              love.graphics.setColor(1, 0, 0, .1)
              love.graphics.rectangle("fill", 0, 0, self.w, self.h)
            end
          end,
          onClick = function (self)
            if action.actionType == game.nextTurns[1] then
              selectedAction = action
            end
          end
        }
        x = x + 170
        table.insert(self.children, child)
      end
    end
  }
  playerActionsUI:load()
  table.insert(menuRadial.children, playerActionsUI)

  endTurnButton = {
    x = width - 170, y = 20, w = 150, h = 150,
    backgroundColor = {.2, .2, .2}, textColor = {1, 1, 1}, text = "ENDTURN", textX = .5*150 - .5*love.graphics.getFont():getWidth("ENDTURN"),
    draw = function (self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      love.graphics.setColor(self.textColor)
      love.graphics.print(self.text, self.textX, .45*self.h)
    end,
    onClick = function(self)
      game:endTurn()
    end
  }
  table.insert(menuRadial.children, endTurnButton)
  actionOverlay = {
    draw = function (self)
      if selectedAction and player then
        love.graphics.setColor(1, 1, 1, .1)
        local dx, dy = math.floor(-zoomX*(mapI%1)*tileSize), math.floor(-zoomY*(mapJ%1)*tileSize)
        love.graphics.translate(mapX+dx, mapY+dy)
        for i=0, tilesDisplayWidth-1 do
          for j=0, tilesDisplayHeight-1 do
            if (manhattanDistance(player, {i=i, j=j})==0 and selectedAction.usableOnSelf) or (manhattanDistance(player, {i=i, j=j})>0 and manhattanDistance(player, {i=i, j=j}) <= selectedAction.range) then
              love.graphics.rectangle("fill", (i-1)*zoomX*tileSize, (j-1)*zoomY*tileSize, zoomX*tileSize, zoomY*tileSize)
            end
          end
        end
      end
    end
  }
  table.insert(uis, actionOverlay)

  nextTurnUIW = 600
  nextTurnUI = {
    x= .5*(width-nextTurnUIW), y = 0,w = nextTurnUIW, h = 100,
    backgroundColor = {.1, .1, .1},
    draw = function(self)
      love.graphics.setColor(self.backgroundColor)
      love.graphics.rectangle("fill", 0, 0, self.w, self.h)
      for n, turn in pairs(game.nextTurns) do
        love.graphics.setColor(.4, .3, .2)
        love.graphics.print(turn, (n-.5)*(nextTurnUIW-20)/5, 40)
      end
    end
  }
  table.insert(uis, nextTurnUI)
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    local i, j = screenToGrid(x, y)
    if map[i] and map[i][j] then
      if selectedAction then
        if selectedAction:try({i=i, j=j}) then
          game:endTurn()
        end
      end
      selectedAction = nil
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


function tests()
  testActions()
  testLivingEntityRessource()
end