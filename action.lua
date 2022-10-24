actionTypesKeys = {"attack", "move", "magic", "miscellaneous"}
actionTypes = {
    attack = {name = "attack", img = nil},
    move = {name = "move", img = nil},
    magic = {name = "magic", img = nil},
    miscellaneous = {name = "miscellaneous", img = nil}
}

function setupActionTypesImages()
    actionTypes.attack.img = love.graphics.newImage("src/img/dice/attack.png")
    actionTypes.move.img = love.graphics.newImage("/src/img/dice/move.png")
    actionTypes.magic.img = love.graphics.newImage("src/img/dice/support.png")
    local canvas = love.graphics.newCanvas(254, 254)
    love.graphics.setCanvas(canvas)
    love.graphics.scale(2)
    love.graphics.setCanvas()
    actionTypes.miscellaneous.img = love.graphics.newImage(canvas:newImageData())
end

function newAction()
    local action = {
        name = "defaultActionName",
        range = 1,
        usableOnSelf = false,
        caster = nil,
        cost = {},
        getDescription = function (self) return "This is the default action description" end,
        activate = function(self) end,
        isTargetValid = function (self, targetCell)
            local d = manhattanDistance(self.caster, targetCell)
            if d > 0 then
                return self.range >= d
            else
                return self.usableOnSelf
            end
        end,
        isCostAvailable = function (self)
            for r, ressource in pairs(self.cost) do
                if not self.caster:isAvailable(ressource) then
                    if self.caster == player then audioManager:playSound(audioManager.sounds.wrong) end
                    return false
                end
            end
            return true
        end,
        try = function (self, targetCell)
            if not self:isCostAvailable() then return false, self.name.."'s cost isn't available" end
            if not self:isTargetValid(targetCell) then return false, "target isn't valid for "..self.name end
            if not self:activate(targetCell) then return false, self.name .. " activation failed" end
            for r, ressource in pairs(self.cost) do
                self.caster:deduct(ressource)
            end
            return true
        end
    }
    return action
end

function manhattanDistance(a, b)
    return math.abs(a.i - b.i) + math.abs(a.j - b.j)
end

