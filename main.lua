-- @file main.lua
-- @author Henry Schmale
-- @date November 28, 2020
--
-- Henry's Space Game in the Love engine.
-- It's my attempt to learn some lua, and practice my game development
-- skills.
--
-- Uses the love engine->https://love2d.org/wiki/love.graphics.line

-- x1,y1 must be lower and more left most
function point_in_bbox(x, y, x1, y1, x2, y2)
    -- printf("x=%d y=%d x1=%d, y1=%d x2=%d y2=%d", x, y, x1, y1, x2, y2)
    return (x >= x1 and x <= x2) and (y >= y1 and y <= y2)
end

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
    player.health = 100
    player.score = 0
    return player
end

function Player:hitTest(e)
    local corners = {
        {self.x, self.y},
        {self.x + self.width, self.y},
        {self.x, self.y + self.height},
        {self.x + self.width, self.y + self.height}
    }

    x2 = e.x + e.width
    y2 = e.y + e.height

    for i=1,#corners do
        if point_in_bbox(corners[i][1], corners[i][2], e.x, e.y, x2, y2) then
            return true
        end
    end

    return false
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
    self.t = self.t + 1
    self.y = self.y + self.dir * 2
end

function Missile:isDead()
    return self.dead or self.y < 0 or self.y > love.graphics.getHeight()
end

function Missile:hitTest(target)
--    target.x <= self.x <= (target.x + target.width)
--          self.x >= target.x and self.x <= (target.x + target.width)
--    target.y <= self.y <= (target.y + target.height)
    if self.x > target.x and self.x < (target.x + target.width) 
            and self.y > target.y and self.y < (target.y + target.width) then
        return true
    end
    return false
end

-- ------------------------------------------------------------------------
-- a series of various patterns for the missiles
-- keys are strings, values are functions accepting a `t` and returning
MISSILE_PATTERN = {}

-- parabola formula f(t) = at^2 + bt + c
-- requirement f(t=0) = 0 ===> c = 0
--
-- Factored formula means one of the terms must be x alone
--
-- (throw_forward)t * 
--
function build_missile_parabola(tf)
    return function(t)
    end
end


-- ------------------------------------------------------------------------

Enemy = {}
Enemy.__index = Enemy

ENEMY_COLLECTION = {}
ENEMY_SPAWN_RESET = 60
ENEMY_SPAWN_TIMER = 0
ENEMY_MISSILE_SPAWN_TIME = 45

function Enemy:create(x, y, enemy_type)
    local enemy = {}
    setmetatable(enemy, Enemy)
    enemy.x = x
    enemy.y = y
    enemy.width = 20
    enemy.height = 20
    enemy.missile_cooldown = 0
    enemy.enemy_type = enemy_type
    table.insert(ENEMY_COLLECTION, enemy)
    return enemy
end

function Enemy:draw()
    love.graphics.circle('fill', self.x + self.width / 2, self.y + self.height / 2, self.width / 2)
end

function Enemy:update()
    self.y = self.y + 1
    self.missile_cooldown = self.missile_cooldown + 1
    -- the enemy can now fire a missile
    if self.missile_cooldown > ENEMY_MISSILE_SPAWN_TIME then
        Missile:create(self.x, self.y+3, MISSILE_FROM_ENEMY, 'enemy')
        self.missile_cooldown = 0
    end
end

function Enemy:isDead()
    return self.dead or self.y > love.graphics.getHeight()
end


-- ------------------------------------------------------------------------

my_stupid_player = Player:create()
gameIsPaused = false

-- ------------------------------------------------------------------------

function love.focus(f) 
    gameIsPaused = not f 
end

function love.draw()
    if my_stupid_player['health'] <= 0 then
        love.graphics.print("Game is over. Click to play again", 400, 300)
        s = "score=" .. my_stupid_player['score'] .. '\nhealth=' .. my_stupid_player['health']
        love.graphics.print(s)
        return
    end

    my_stupid_player:draw_player()
    for i=1,#MISSILE_COLLECTION do
        MISSILE_COLLECTION[i]:draw()
    end
    for i=1,#ENEMY_COLLECTION do
        ENEMY_COLLECTION[i]:draw()
    end
    
    s = "score=" .. my_stupid_player['score'] .. '\nhealth=' .. my_stupid_player['health']
    love.graphics.print(s)
end

function printf(...) 
    print(string.format(...)) 
end

function love.update(dt)
    if my_stupid_player['health'] <= 0 then
        gameIsPaused = true
    end

    if not gameIsPaused then
        -- printf("e#=%d m#=%d", #ENEMY_COLLECTION, #MISSILE_COLLECTION)
        ENEMY_SPAWN_TIMER = ENEMY_SPAWN_TIMER + 1
        if ENEMY_SPAWN_TIMER > ENEMY_SPAWN_RESET then
            Enemy:create(love.math.random() * love.graphics.getWidth(), 50, 'zigzag')
            ENEMY_SPAWN_TIMER = 0
        end

        my_stupid_player:update_player()
        for i, m in ipairs(MISSILE_COLLECTION) do
            m:update()
        end

        for i, e in ipairs(ENEMY_COLLECTION) do
            e:update()
            if my_stupid_player:hitTest(e) then
                e.dead = true
                my_stupid_player.health = my_stupid_player.health - 20
            end
            if e:isDead() then
                table.remove(ENEMY_COLLECTION, i)
            end
        end
       
        for i, m in ipairs(MISSILE_COLLECTION) do
            for j,e in ipairs(ENEMY_COLLECTION) do
                if m:hitTest(e) then
                    m["dead"] = true
                    my_stupid_player['score'] = my_stupid_player['score'] + 10
                    table.remove(ENEMY_COLLECTION, j)
                end
            end
            if m:hitTest(my_stupid_player) then
                -- handle player hit
                my_stupid_player['health'] = my_stupid_player['health'] - 10
                m['dead'] = true
            end
            if m:isDead() then
                table.remove(MISSILE_COLLECTION, i)
            end
        end
    end  -- end the paused block
end

function love.mousepressed(x, y, button, istouch, presses)
    if my_stupid_player['health'] <= 0 and gameIsPaused then
        gameIsPaused = false
        ENEMY_COLLECTION = {}
        MISSILE_COLLECTION = {}
        my_stupid_player = Player:create()
    end
end
