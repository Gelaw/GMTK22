require "base"
require "data"
require "ui"
require "map"
require "entity"
require "action"
require "mapFile"
require "item"
require "tests"
game = require "game"

function projectSetup()
  
  --font
  love.graphics.setBackgroundColor(.3, .3, .3)
  -- font = love.graphics.newFont("src/fonts/Quantum.otf", 25)
  -- love.graphics.setFont(font)
  
  --To remove--
  font = love.graphics.getFont()
  ---

  --Load images
  diceImg = love.graphics.newImage("src/img/dice/dice.png")
  fuzzyDicesImages = {
    love.graphics.newImage("src/img/dice_frame/deP1.png"),
    love.graphics.newImage("src/img/dice_frame/deP2.png"),
    love.graphics.newImage("src/img/dice_frame/deP3.png"),
    love.graphics.newImage("src/img/dice_frame/deP4.png"),
    love.graphics.newImage("src/img/dice_frame/deP5.png")
  }
  
  dungeonSprites = love.graphics.newImage("src/img/sprites/ProjectUtumno_full.png")
  spriteSize = 32
  
  todoQuad = love.graphics.newQuad(37 * spriteSize,  50* spriteSize, spriteSize, spriteSize,
  dungeonSprites:getWidth(), dungeonSprites:getHeight())
  
  itemsQuads = {
    sword = love.graphics.newQuad(2 * spriteSize,  49* spriteSize, spriteSize, spriteSize,
    dungeonSprites:getWidth(), dungeonSprites:getHeight()),
    armor = love.graphics.newQuad(15 * spriteSize,  38* spriteSize, spriteSize, spriteSize,
    dungeonSprites:getWidth(), dungeonSprites:getHeight())
  }
  
  
  
  oldHeroImage = love.graphics.newImage("src/img/sprites/oldHero.png")
  knightImage = love.graphics.newImage("src/img/sprites/knight.png")
  mageImage = love.graphics.newImage("src/img/sprites/mage.png")
  
  setupActionTypesImages()
  
  gmtkImage = love.graphics.newImage("src/img/gmtkLogo.jpg")
  ssLogo = love.graphics.newImage("src/img/SacraScriptura.png")
  menuBackground = love.graphics.newImage("src/img/Menu.png")
  
  --load music and sounds
  audioManager:loadMusic("mainTheme", "src/snd/test3.mp3")
  audioManager:loadMusic("prairieTheme", "src/snd/prairie.mp3")
  
  audioManager:loadSoundEffect("click",       "src/snd/soundEffect/snd_btnClick.mp3")
  audioManager:loadSoundEffect("attack",      "src/snd/soundEffect/snd_heroAttack.mp3")
  audioManager:loadSoundEffect("heal",        "src/snd/soundEffect/snd_heroHeal.mp3")
  audioManager:loadSoundEffect("magic",       "src/snd/soundEffect/snd_heroMagic.mp3")
  audioManager:loadSoundEffect("walk",        "src/snd/soundEffect/snd_heroWalk.mp3")
  audioManager:loadSoundEffect("mouseclick",  "src/snd/soundEffect/snd_mouseClick.mp3")
  audioManager:loadSoundEffect("wrong",       "src/snd/soundEffect/snd_wrong.mp3")
  
  
  
  addDrawFunction(function ()
    if mapHidden then
      love.graphics.setColor(1,1,1)
      love.graphics.draw(menuBackground, -width*.5, -height*.5, 0, width/menuBackground:getWidth(), height/menuBackground:getHeight())
    end
  end, 1)

  
  
  
  setupMap()
  setupMapView()
  setupTileset()
  setupUIs()
  
  
  modes = {"normal", "instantStart", "testing"}
  mode = mode or "instantStart"
  if mode == "normal" then
    GMTKScreen = {
      image = gmtkImage,
      
      timeLeft = 3,
      x=-width/2, y=-height/2,
      draw = function (self)
        love.graphics.setColor(1, 1, 1, self.timeLeft)
        love.graphics.translate(self.x, self.y)
        love.graphics.draw(self.image, 0, 0, 0, width/self.image:getWidth(), height/self.image:getHeight())
        love.graphics.setColor(1,1,1)
        love.graphics.circle("fill",ssLogo:getWidth()/10+1,ssLogo:getHeight()/10,105)
        love.graphics.draw(ssLogo, 0, 0, 0, width/ssLogo:getWidth()/5, height/ssLogo:getHeight()/5)
        love.graphics.print("Sacra Scriptura",ssLogo:getWidth()/20, ssLogo:getHeight()/5)
      end,
      onTermination = function ()
        ShowMenu()
      end
    }
    table.insert(particuleEffects, GMTKScreen)
    return 
  end
  if mode == "instantStart" then
    HideMenu()
    game:start()
  end
  if mode == "testing" then
    HideMenu()
    game:start()
    testActions()
    testLivingEntityRessource()
  end
end



function love.mousemoved(x, y, dx, dy)
  local mouseoverUI = UIMouseMoved(x, y, dx, dy)
  if not mouseoverUI then
    
  end
end

function love.mousepressed(x, y, button, isTouch)
  local press = UIMousePress(x, y , button)
  if not press then
    game:processClick(x, y)
  end
end

function love.mousereleased(x, y, button, isTouch)
  UIMouseRelease(x, y, button)
end

function love.keypressed(key, scancode, isrepeat)
  if not victory.hidden then game:start() end
  if not defeat.hidden then ShowMenu() end
  if love.keyboard.isDown("lctrl") and love.keyboard.isDown("rctrl") then
    victory.hidden = false
  end
  if key == "escape" then
    if MenuScreen.hidden and mode == "normal" then
      ShowMenu()
    else
      love.event.quit()
    end
  end
  if player and player.actions then
    if player.actions[tonumber(key)] then
      selectedAction = player.actions[tonumber(key)]
    elseif key == "space" then
      audioManager:playSound(audioManager.sounds.click)
      game:endTurn()
    end
  end
end

function getEntityOn(i, j)
  for e, entity in pairs(entities) do
    if entity.i and entity.i == i and entity.j and entity.j == j then return entity end
  end
end



function tests()
  testLivingEntityRessource()
  testActions()
end



function setupUpgrades()
  upgradeText = ""
  upgrades = {
    {player.actions[2], "range", 1},
    {player.actions[3], "healAmout", 1},
    {player.actions[4], "damage", 5},
    {player.actions[4], "range", 5},
    {player.actions[1], "range", 5},
    {player.ressources.life, "max", 59},
    {player.ressources.mana, "max", 19}
  }
  upgradeWeightSum = 0
  for u, upgrade in pairs(upgrades) do
    upgradeWeightSum = upgradeWeightSum + upgrade[3]
  end
end

function upgradePlayer()
  local roll = math.random(upgradeWeightSum)
  for u, upgrade in pairs(upgrades) do
    roll = roll - upgrade[3]
    if roll < 0 then
      upgradeText = upgrade[1].name .." gained 1 " .. upgrade[2] .."\n" .. upgradeText
      upgrade[1][upgrade[2]] = upgrade[1][upgrade[2]] + 1
      break
    end
  end
end