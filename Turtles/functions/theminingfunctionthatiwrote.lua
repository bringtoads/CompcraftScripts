local DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}

local gpsPos = {
    x = 0,
    y = 0,
    z = 0
}

local position = {
    x = 0,
    y = 0,
    z = 0
}
local STATUS = {
    IDLE = "idle",
    MINING = "mining",
    STOPPED = "stopped",
    RUNNING = "running"
}
local direction = DIRECTIONS.SOUTH
------------------------movements--------------------------------------------------------------------------
local function turnRight()
    turtle.turnRight()
    direction = (direction + 1) % 4
end
local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 1) % 4
    if direction < 0 then
        direction = direction + 4
    end
end
local function forward()
    if turtle.forward() then
        print("Moved forward successfully.")
        updatePosition()
    else
        print("Failed to move forward.")
    end
end
local function backward()
    if turtle.back() then
        print("Moved backward successfully.")
        updatePosition()
    else
        print("Failed to move backward.")
    end
end
local function right()
    turnRight()
    if turtle.forward() then
        print("Moved right successfully.")
        updatePosition()
    else
        turnLeft()
        print("Failed to move right.")
    end
end
local function left()
    turnLeft()
    if turtle.forward() then
        print("Moved left successfully.")
        updatePosition()
    else
        turnRight()
        print("Failed to move left.")
    end
end
local function up()
    if turtle.up() then
        position.y = position.y + 1
        print("Moved up successfully.")
    else
        print("Failed to move up.")
    end

end
local function down()
    if turtle.down() then
        position.y = position.y - 1
        print("Moved down successfully.")
    else
        print("Failed to move down.")
    end
end
---------------------------------------Dig Functions--------------------------------------------------------
-- using this in the mine function
local function digForward()
    turtle.dig()
    turtle.forward()
    updatePosition()
end
local function digBackward()
    turtle.turnRight()
    direction = (direction + 1) % 4
    turtle.turnRight()
    direction = (direction + 1) % 4
    turtle.dig()
    turtle.forward()
    updatePosition()
end
local function digUp()
    turtle.digUp()
    turtle.up()
    position.y = position.y + 1
end
local function digDown()
    turtle.digDown()
    turtle.down()
    position.y = position.y - 1
end
local function digRight()
    turtle.turnRight()
    direction = (direction + 1) % 4
    turtle.dig()
    turlte.forward()
    updatePosition()
end
local function digLeft()
    turtle.turnLeft()
    turtle.dig()
    direction = (direction - 1) % 4
    if direction < 0 then
        direction = direction + 4
    end
    turtle.forward()
end
local function yAlternate(flag)
    if flag == 0 then
        digDown()
    elseif flag % 2 == 0 then
        digDown()
        turnRight()
    else
        digDown()
        turnLeft()
    end
end
local function xAlternate(flag)
    if flag % 2 == 0 then
        turnRight()
        digForward()
        turnRight()
    else
        turnLeft()
        digForward()
        turnLeft()
    end
end
local function mine(targetx, targety, targetz)
    local flagx = 0
    local flagy = 0
    for y = 1, targety do
        yAlternate(flagy)
        for x = 1, targetx do
            for z = 1, targetz - 1 do
                digForward()
            end
            if x < targetx - 1 then
                xAlternate(flagx)
                flagx = flagx + 1
            end
        end
        flagy = flagy + 1
        flagx = flagx + 1
    end
end

local args = {...}

-- Check if enough arguments are provided
if #args < 3 then
    print("Usage: mine <x> <y> <z>")
    return
end

-- Parse the arguments as numbers
local x = tonumber(args[1])
local y = tonumber(args[2])
local z = tonumber(args[3])

mine(x, y, z)
