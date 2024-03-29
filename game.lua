
local game = {
  gameState = "unlaunched",
  nTurn = 1,
  level = 10,
  start = function(self)
    --game setup
    self.nTurn = 1
    mapHidden = false
    victory.hidden = true
    self.level = self.level + 1
    setupMap()
    fillMap()
    --player setup - reset existing player entity or create new one 
    if not player then
      player = newPlayerCharacter()
      local sword = newItem({name = "sword",  quad = itemsQuads.sword, stats = {weaponAttack = 1}})
      newItemEntity(sword, 3, 4)
      setupUpgrades()
    else
      for e, entity in pairs(entities) do
        entity.terminated = true
      end
      player.terminated = false
      player.i, player.j = 3, 3
      player.ressources.life.quantity = player.ressources.life.max
      player:snapToGrid()
    end
    inventoryUI:onGameStart()

    -- enemy generation
    spawnTypes = {"oneshot"}
    if game.level >= 2 then
      table.insert(spawnTypes, "basic")
    end
    if game.level >= 3 then
      table.insert(spawnTypes, "runner")
    end
    if game.level >= 5 then
      table.insert(spawnTypes, "tank")
    end
    if game.level >= 10 then
      table.insert(spawnTypes, "boss")
    end
    forces = 0
    forceTable = {1, 2, 1, 4, 12}
    while forces < game.level do
      n = math.random(#spawnTypes)
      forces = forces + forceTable[n]
      spawn(spawnTypes[n])
    end

    -- trigger fightstart event of entities
    for e, entity in pairs(entities) do
      entity:triggerGameplayEvent("fightStart")
    end
  end,
  finish = function (self)
    self.level = 0
    player = nil
    for e, entity in pairs(entities) do
      entity.terminated = true
    end
  end,
  endTurn = function (self)
    selectedAction = nil
    self:playIAs()
    if player:isDead() then
      defeat.hidden = false
    end
    game.nTurn = game.nTurn + 1
    for e, entity in pairs(entities) do
      -- tick down effect duration 
      if entity.tickEffects then entity:tickEffects() end
      -- trigger new turn effects
      entity:triggerGameplayEvent("turnStart")
    end
  end,
  playIAs = function (self)
    local c = 0
    for e, entity in pairs(entities) do
      if entity ~= player and entity.isDead and not entity:isDead() then
        c = c + 1
        local availableActions = {}
        for a, action in pairs(entity.actions) do
          if action.actionType == "attack" then
            table.insert(availableActions, action)
          end
        end
        if #availableActions > 0 then
          local iachoice = availableActions[math.random(#availableActions)]
          if not iachoice:try({i=player.i, j=player.j}) and not iachoice:try({i=entity.i, j=entity.j}) then
            local distance = math.dist(player.i, player.j, entity.i, entity.j)
            local target = {i=entity.i, j=entity.j}
            local secondChoiceDistance = distance
            local secondChoiceTarget = target
            for i = - iachoice.range, iachoice.range do
              for j = -iachoice.range, iachoice.range do
                local ni, nj = entity.i+i, entity.j+j
                if map[ni] and map[ni][nj] and map[ni][nj] > 0 then
                  if manhattanDistance(entity, {i=ni, j=nj}) <= iachoice.range then
                    local d = math.dist(player.i, player.j, ni, nj)
                    if d < distance then
                      secondChoiceDistance = distance
                      secondChoiceTarget = target
                      target = {i=ni, j=nj}
                      distance = d
                    end
                  end
                end
              end
            end
            if not iachoice:try(target) then
              iachoice:try(secondChoiceTarget)
            end
          end
        end
      end
    end
    if c == 0 then 
      victory.hidden = false
    end
  end,
  processClick = function (self, x, y)
    local i, j = screenToGrid(x, y)
    if map[i] and map[i][j] and map[i][j] > 0 then
      if selectedAction then
        local tentative, msg = selectedAction:try({i=i, j=j})
        if tentative then
          game:endTurn()
        else
          -- print(msg)
        end
      end
      selectedAction = nil
    end
  end
}


function spawn(type)
  if ennemyTypes[type] then
    local ennemy = ennemyTypes[type]()
    ennemy.i, ennemy.j = math.random(8, mapWidth), math.random(8, mapHeight)
    ennemy:initEntity()
    return ennemy
  end
end
  
function newPlayerCharacter()
  playerClass = "monk" -- fighter mage warrior monk

  local playerChar = applyParams(newLivingEntity(), {image = knightImage, i = 3, j=3, w=32, h=32, spriteSet = {width = 20, height = 20}})
  playerChar:addAction(actions.Walk({range=2}))
  playerChar:addAction(actions.WeaponAttack())
  classes[playerClass]:setup(playerChar)
  for r, ressourceType in pairs(ressourceTypes) do
    local stat = playerChar:getEffectiveStat(r)
    local defaultValue = playerChar:getEffectiveStat("default_"..r)
    if stat > 0 then
      playerChar:addRessourceBank(r, stat, defaultValue >0 and defaultValue or nil)
    end
  end
  playerChar.inventory.size = 20
  playerChar:initEntity()
  return playerChar
end

function spawnManaline()
  local manaline = newEntity()
  manaline.color = {0, 0, 1}
  manaline.blockPath = false

  manaline.i, manaline.j = math.random(1, mapWidth), math.random(1, mapHeight)  
  manaline.onWalkingOn = function (self, walkingEntity)
    if walkingEntity.ressources["mana"] and walkingEntity.ressources["mana"].quantity < walkingEntity.ressources["mana"].max then
      walkingEntity:credit(newRessource("mana", 1))
      self.terminated = true
      spawnManaline()
    end
  end
  manaline:initEntity()
end

eventTypes = {
  "fightStart"; "fightEnd";
  "turnStart"; "turnEnd";
  "damageTaken"; "damageDealt";
  "bonusReceived"; "bonusLost";
  "malusReceived"; "malusLost";
}

return game