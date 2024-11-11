local args = {...}

-- Check if enough arguments are provided
if #args < 3 then
    print("Usage: mine <x> <y> <z>")
    return
end

-- Parse the arguments as numbers
local length = tonumber(args[1])
local height = tonumber(args[2])
local width = tonumber(args[3])

if not length or not height or not width then
    print("Invalid arguments. Provide numeric values for length, height, and breadth.")
    return
end

-- Initialize variables
local direction = 0 -- 0 = North, 1 = East, 2 = South, 3 = West
local flagx = 0
local flagy = 0

-- Define movement functions
local function forward()
    turtle.dig()
    turtle.forward()
end

local function down()
    turtle.digDown()
    turtle.down()
end

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

local function xalternate(flag)
    if flag % 2 == 0 then
        turnRight()
        forward()
        turnRight()
    else

        turnLeft()
        forward()
        turnLeft()
    end
end

local function yAlternate(flag)
    if flag == 0 then
        down()
    elseif flag % 2 == 0 then
        down()
        turnRight()
    else
        down()
        turnLeft()
    end
end

-- Mining logic
for y = 1, height do
    yAlternate(flagy)
    for x = 1, length do
        for z = 1, width - 1 do
            forward()
        end
        if x < length - 1 then
            xalternate(flagx)
            flagx = flagx + 1
        end
    end
    flagx = flagx + 1
    flagy = flagy + 1
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
