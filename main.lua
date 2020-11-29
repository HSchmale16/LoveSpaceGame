-- @file main.lua
-- @author Henry Schmale
-- @date November 28, 2020
--
-- Henry's Space Game in the Love engine.
-- It's my attempt to learn some lua, and practice my game development
-- skills.
--
-- Uses the love engine->https://love2d.org/wiki/love.graphics.line


Player = {}
Player.__index = Player

PLAYER_MISSILE_COOLDOWN_TIMING = 20

function Player:create()
    local player = {}
    setmetatable(player, Player)
    player.x = 400
    player.y = 300
    player.v_x = 0
    player.v_y = 0
    player.width = 30
    player.height = 40
    player.moveSpeed = 2
    player.x_accel = .25
    player.missileCooldown = 0
    return player
end

function Player:draw_player()
    love.graphics.line(self.x, self.y + self.height, self.x + self.width / 2, self.y)
    love.graphics.line(self.x, self.y + self.height, self.x + self.width, self.y + self.height)
    love.graphics.line(self.x + self.width/2, self.y, self.x + self.width, self.y + self.height)
    --love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end

function Player:update_player() 
    -- move up
    if love.keyboard.isDown("up") then
        self.y = self.y - self.moveSpeed
    end
    if love.keyboard.isDown("down") then
        self.y = self.y + self.moveSpeed
    end
    if love.keyboard.isDown("left") then
        self.v_x = math.max(self.v_x - self.x_accel, -4)
    end
    if love.keyboard.isDown("right") then
        self.v_x = math.min(self.v_x + self.x_accel, 4)
    end
    if love.keyboard.isDown("space") and self.missileCooldown <= 0 then
        Missile:create(self.x + self.width/2, self.y, MISSILE_FROM_PLAYER, 'player')
        self.missileCooldown = PLAYER_MISSILE_COOLDOWN_TIMING
    end
    self.x = self.x + self.v_x
    self.y = self.y + self.v_y
    
    if self.x < 0 then
        self.x = love.graphics.getWidth()
    end
    if self.x > love.graphics.getWidth() then
        self.x = 0
    end


    self.missileCooldown = self.missileCooldown - 1
end


-- ------------------------------------------------------------------------

Missile = {}
Missile.__index = Missile

MISSILE_FROM_ENEMY  =  1
MISSILE_FROM_PLAYER = -1
MISSILE_COLLECTION = {}
MISSILE_COUNT = 0

function Missile:create(x, y, dir, owner)
    local missile = {}
    setmetatable(missile, Missile)
    missile.x = x
    missile.y = y
    missile.t = 0
    missile.dir = dir
    missile.owner = owner
    missile.dead = false
    table.insert(MISSILE_COLLECTION, missile) 
    return missile
end

function Missile:draw()
    local r,g,b,a = love.graphics.getColor()
    love.graphics.setColor(255,0,0,255)
    love.graphics.line(self.x, self.y, self.x, self.y + 10 * self.dir)
    love.graphics.setColor(r,g,b,a)
end

function Missile:update()
    missile.t = missile.t + 1
    self.y = self.y + self.dir
end

function Missile:isDead()
    return self.dead or self.y < 0 or self.y > 600
end

function Missile:hitTest(target)
--    target.x <= self.x <= (target.x + target.width)
--          self.x >= target.x and self.x <= (target.x + target.width)
--    target.y <= self.y <= (target.y + target.height)
    if self.x >= target.x and self.x <= (target.x + target.width) 
            and self.y >= target.y and self.y <= (target.y + target.width) then
        print("HIT TEST SUCCESS")
        return true
    end
    return false
end

-- ------------------------------------------------------------------------

Enemy = {}
Enemy.__index = Enemy

ENEMY_AI_TABLE = {}

function ENEMY_AI_TABLE:zigzag(enemy)
end


ENEMY_COLLECTION = {}
ENEMY_SPAWN_RESET = 60
ENEMY_SPAWN_TIMER = 0


function Enemy:create(x, y, enemy_type)
    local enemy = {}
    setmetatable(enemy, Enemy)
    enemy.x = x
    enemy.y = y
    self.width = 20
    self.height = 20
    enemy.enemy_type = enemy_type
    table.insert(ENEMY_COLLECTION, enemy)
    return enemy
end

function Enemy:draw()
    love.graphics.circle('fill', self.x + self.width / 2, self.y + self.height / 2, self.width / 2)
end

function Enemy:update()
    ENEMY_AI_TABLE[self.enemy_type](self)
end

function Enemy:isDead()
    return self.y > love.graphics.getHeight()
end


-- ------------------------------------------------------------------------

my_stupid_player = Player:create()
gameIsPaused = false

-- ------------------------------------------------------------------------

function love.focus(f) 
    gameIsPaused = not f 
end

function love.draw()
    my_stupid_player:draw_player()
    for i=1,#MISSILE_COLLECTION do
        MISSILE_COLLECTION[i]:draw()
    end
    for i=1,#ENEMY_COLLECTION do
        ENEMY_COLLECTION[i]:draw()
    end
end

function printf(...) print(string.format(...)) end

function love.update(dt)
    printf("e#=%d m#=%d", #ENEMY_COLLECTION, #MISSILE_COLLECTION)
    ENEMY_SPAWN_TIMER = ENEMY_SPAWN_TIMER + 1
    if ENEMY_SPAWN_TIMER > ENEMY_SPAWN_RESET then
        Enemy:create(love.math.random() * love.graphics.getWidth(), -50, 'zigzag')
        ENEMY_SPAWN_TIMER = 0
    end

    my_stupid_player:update_player()
    for i, m in ipairs(MISSILE_COLLECTION) do
        m:update()
    end

    for i, e in ipairs(ENEMY_COLLECTION) do
        e:update()
        if e:isDead() then
            table.remove(ENEMY_COLLECTION, i)
        end
    end
   
    for i, m in ipairs(MISSILE_COLLECTION) do
        for j,e in ipairs(ENEMY_COLLECTION) do
            if m:hitTest(e) then
                m["dead"] = true
                table.remove(ENEMY_COLLECTION, j)
            end
        end
        if m:hitTest(my_stupid_player) then
            -- handle player hit
        end
        if m:isDead() then
            table.remove(MISSILE_COLLECTION, i)
        end
    end
end
