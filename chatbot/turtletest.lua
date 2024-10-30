-- t10
---------------------  S  -----------------------
---------------------  Z+ -----------------------
-----  E  ------------------------------------- W-  ----
-----  X+  ------------0---------t()----------  X-  ----
-------------------------------------------------
---------------------  N  ------------------
---------------------  Z- --------------------
-- facing direction
-- (forward z+) south = 0
-- (right x-) west = 1
-- (backward z-) north = 2
--  (left x+) east  = 3
-- (up y+) =4
-- (donw y-) = 5
-- place turtle facing south
-- local southdir = "z+"     --0
-- local westdir = "x-"      --1
-- local northdir = "z-"     -- 2
-- local eastdir = "x+"      -- 3
-- local ypositivedir = "y+" --4
-- local ynegativedir = "y-" --5
_OreLevel = 160
-- _HomeDirection = { x = 69, y = 38, z = 85 }
_HomeDirection = {
    x = 249,
    y = 163,
    z = -301
}
_DirectionLog = {
    x = 249,
    y = 163,
    z = -301
}
_MaxBoundries = {
    x = 500,
    z = 500
}

local direction = 0 -- 0 = South, 1 = West, 2 = North, 3 = East

local function updatePosition(success)
    if success then
        -- Update the position based on the current direction
        if direction == 0 then -- Facing South
            _DirectionLog.z = _DirectionLog.z + 1
        elseif direction == 1 then -- Facing West
            _DirectionLog.x = _DirectionLog.x - 1
        elseif direction == 2 then -- Facing North
            _DirectionLog.z = _DirectionLog.z - 1
        elseif direction == 3 then -- Facing East
            _DirectionLog.x = _DirectionLog.x + 1
        elseif direction == 4 then -- Moving up (Y+)
            _DirectionLog.y = _DirectionLog.y + 1
        elseif direction == 5 then -- Moving down (Y-)
            _DirectionLog.y = _DirectionLog.y - 1
        end
    end
end

-- Function to initialize the Turtle
local function init()
    print("Turtle initialization started.")

    -- Refuel if the turtle is low on fuel
    if turtle.getFuelLevel() < 100 then
        print("Low fuel. Please refuel the turtle.")
        return false -- Abort initialization
    end

    print("Turtle initialized with enough fuel.")
    return true -- Initialization successful
end

-- Function to check if inventory is full
local function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

local function justDig()
    turtle.dig()
    turtle.digUp()
    turtle.digDown()
    turtle.turnRight()
    turtle.dig()
    turtle.digUp()
    turtle.digDown()
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.dig()
    turtle.digUp()
    turtle.digDown()
    turtle.turnRigt()
end
local function checkIfBedrock()
end

-- if turn right change facing direction to west
local function turnRight()
    turtle.turnRight()
    direction = (direction + 1) % 4 -- Update the direction (wrap around 0-3)
end

-- Example function to turn the turtle to the left (counter-clockwise)
local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 1) % 4 -- Update the direction (wrap around 0-3)
    if direction < 0 then
        direction = 3 -- Fix wrap around for negative values
    end
end
local function checkBlock()

end
-- move forward
local function forward(times)
    -- z+
    times = times or 1
    direction = 0
    for i = 1, times do
        justDig()
        local status = turtle.forward()
        if status then
            turtle.forward()
            updatePosition(status)
        end
    end
end
local function backward(times)
    -- z+
    times = times or 1
    direction = 2
    for i = 1, 2 do
        turnRight()
    end
    for i = 1, times do
        justDig()
        local status = turtle.forward()
        if status then
            turtle.forward()
            updatePosition(status)
        end
    end
end
local function right(times)
    -- x+
    times = times or 1
    turtle.turnRight()
    direction = 1
    for i = 1, times do
        justDig()
        local status = turtle.forward()
        if status then
            turtle.forward()
            updatePosition(status)
        end
    end
end

-- left
local function left(times)
    -- x-
    times = times or 1
    turtle.turnLeft()
    direction = 3
    for i = 1, times do
        turtle.dig()
        turtle.forward()
        updatePosition()
    end
end

local function up(times)
    -- y+
    times = times or 1
    direction = 4
    for i = 1, times do
        turtle.digUp()
        local status = turtle.up()
        if status then
            turtle.up()
            updatePosition()
        else
            -- check for unbreakeable block

        end
    end
end
local function down(times)
    -- y-
    times = times or 1
    direction = 5
    for i = 1, times do
        turtle.digDown()
        local status = turtle.down()
        if status then
            turtle.down()
            updatePosition(status)
        end
    end
end

local function stripMineWithSideCheck(length, width)
    local initialX, initialY, initialZ = _DirectionLog.x, _DirectionLog.y, _DirectionLog.z

    -- Helper function to move forward and check side blocks
    local function moveAndCheckSides()
        -- Dig the front block and move forward
        forward()
        -- Check and dig the block to the left
        turtle.turnLeft()
        justDig()
        turtle.turnRight()
        turtle.turnRight()
        justDig()
        turtle.turnLeft()
    end

    -- Function to mine a straight line and check sides
    local function mineStraightLine(length)
        for i = 1, length do
            moveAndCheckSides()
        end
    end

    -- Function to return to the starting point after digging
    local function returnToStart()
        -- turtle.turnRight()
        -- turtle.turnRight() -- turn 180 to face the start point
        -- for i = 1, length do
        --     turtle.forward()
        --     updatePosition()
        -- end
        backward(length)
        turtle.turnRight()
        turtle.turnRight() -- face the original direction again
    end

    -- Start strip mining
    for w = 0, width - 1, 2 do
        -- Mine forward
        mineStraightLine(length)

        -- Return to starting point
        returnToStart()

        -- Move 2 blocks to the right
        turtle.turnRight()
        for i = 1, 2 do
            turtle.dig()
            turtle.forward()
            updatePosition()
        end
        turtle.turnLeft()
    end

    -- Return to the exact initial coordinates
    returnToStart()

    -- Move back to the original initial point if needed
    while _DirectionLog.x > initialX do
        turtle.turnRight()
        turtle.forward()
        updatePosition()
    end
    print("Returned to initial starting position: X=" .. initialX .. ", Y=" .. initialY .. ", Z=" .. initialZ)
end

-- Example usage:
-- stripMineWithSideCheck(20, 10)

-- Function to return home by retracing steps
local function returnHome()
    -- Return to original Y position
    while _DirectionLog.y < _HomeDirection.y do
        if not up() then
            print("Unable to move up, digging up...")
            turtle.digUp()
        end
    end
    while _DirectionLog.y > _HomeDirection.y do
        if not down() then
            print("Unable to move down, digging down...")
            turtle.digDown(1)
        end
    end

    -- Move in X direction
    local targetX = _HomeDirection.x
    while _DirectionLog.x < targetX do
        turnToDirection(1) -- Turn East
        if not forward() then
            print("Unable to move forward, digging...")
            turtle.dig()
        end
    end
    while _DirectionLog.x > targetX do
        turnToDirection(3) -- Turn West
        if not forward() then
            print("Unable to move forward, digging...")
            turtle.dig()
        end
    end

    -- Move in Z direction
    local targetZ = _HomeDirection.z
    while _DirectionLog.z < targetZ do
        turnToDirection(2) -- Turn South
        if not forward() then
            print("Unable to move forward, digging...")
            turtle.dig()
        end
    end
    while _DirectionLog.z > targetZ do
        turnToDirection(0) -- Turn North
        if not forward() then
            print("Unable to move forward, digging...")
            turtle.dig()
        end
    end

    print("Returned home to coordinates: X=" .. _HomeDirection.x .. ", Y=" .. _HomeDirection.y .. ", Z=" ..
              _HomeDirection.z)
end

-- Function to refuel the turtle
local function refuel()
    turtle.refuel()
end
local function checkFuel()
    return turtle.getFuelLevel()
end

-- Function to mine for diamonds
local function mineForDiamonds()
    -- reach the y cordinate
    while _DirectionLog.y > _OreLevel do
        local success, block = turtle.inspectDown()
        -- if bottom block is bed rock move 5 blocks up 5 blocks forward and down 4 blocks
        if success and block.name == "minecraft:bedrock" then
            print("bedrock found! Unbreakeable block going up - blocks")
            up(5)
            forward(5)
            down(4)
        end
        down()
        print(_DirectionLog.y)
    end
    while checkFuel() > 500 do
        local success, block = turtle.inspect()
        if success and block.name == "minecraft:bedrock" then
            print("bedrock found! Unbreakeable block going up - blocks")
            up(5)
            forward(2)
            down(5)
        end
        stripMineWithSideCheck(10, 10)
    end
    returnHome()
end

-- Main execution
if init() then
    print("Starting mining operation for diamonds...")
    mineForDiamonds()
else
    print("Initialization failed.")
end
