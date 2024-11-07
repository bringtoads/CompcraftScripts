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

local function yalternate(flag)
    if flag == 0 then
        down()
    else
        down()
        if flag % 2 == 0 then
            turnLeft()
        else
            turnRight()
        end
    end
end

-- Mining logic
for y = 0, height - 1 do
    yalternate(flagy)
    for x = 0, length - 1 do
        for z = 1, width do
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

print("Mining operation complete!")
