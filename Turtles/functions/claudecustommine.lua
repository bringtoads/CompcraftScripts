-- Check if enough arguments are provided
if #args < 3 then
    print("Usage: mine <x> <y> <z>")
    return
end

-- Parse the arguments as numbers
local targetx = tonumber(args[1])
local targety = tonumber(args[2])
local targetz = tonumber(args[3])

if not targetx or not targety or not targetz then
    print("Invalid arguments. Provide numeric values for length, height, and breadth.")
    return
end

-- Initialize variables
local direction = 0 -- 0 = North, 1 = East, 2 = South, 3 = West
local flagx = 0
local flagy = 0

-- Update turtle's position or state
local function updatecod()
    -- Optional: Add code to track the turtle's position if needed
end

-- Define movement functions
local function forward()
    turtle.dig()
    turtle.forward()
    updatecod()
end

local function down()
    turtle.digDown()
    turtle.down()
    updatecod()
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
for y = 0, targety - 1 do
    yalternate(flagy)
    for x = 1, targetx - 1 do
        for z = 1, targetz do
            forward()
        end
        if x < targetx - 1 then
            xalternate(flagx)
            flagx = flagx + 1
        end
    end
    flagx = flagx + 1
    flagy = flagy + 1
end

print("Mining operation complete!")
