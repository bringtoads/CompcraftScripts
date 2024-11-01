-- Flatten land within a polygon defined by 4 coordinates to target Y level
-- Usage: flatten <targetY> <x1> <z1> <x2> <z2> <x3> <z3> <x4> <z4>
-- Direction constants
local DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}

-- Current heading of the turtle
local currentHeading = DIRECTIONS.SOUTH

-- Turn to face a specific direction
function turnToDirection(targetDirection)
    while currentHeading ~= targetDirection do
        turtle.turnRight()
        currentHeading = (currentHeading - 1) % 4
    end
end

-- Check if a point is inside a polygon using ray casting algorithm
function isPointInPolygon(x, z, polyX, polyZ)
    local inside = false
    local j = #polyX

    for i = 1, #polyX do
        if (polyZ[i] < z and polyZ[j] >= z or polyZ[j] < z and polyZ[i] >= z) and
            (polyX[i] + (z - polyZ[i]) / (polyZ[j] - polyZ[i]) * (polyX[j] - polyX[i]) < x) then
            inside = not inside
        end
        j = i
    end

    return inside
end

-- Get fuel level and refuel if needed
function checkFuel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel < 100 then
        for i = 1, 16 do
            turtle.select(i)
            if turtle.refuel(0) then
                turtle.refuel()
            end
        end
    end
    return turtle.getFuelLevel() > 0
end

-- Move to specified coordinates
function moveToCoord(targetX, targetZ, currentX, currentZ)
    -- Move in X direction
    if targetX > currentX then
        turnToDirection(DIRECTIONS.EAST)
    elseif targetX < currentX then
        turnToDirection(DIRECTIONS.WEST)
    end

    local diffX = math.abs(targetX - currentX)
    for i = 1, diffX do
        while not turtle.forward() do
            turtle.dig()
        end
    end

    -- Move in Z direction
    if targetZ > currentZ then
        turnToDirection(DIRECTIONS.SOUTH)
    elseif targetZ < currentZ then
        turnToDirection(DIRECTIONS.NORTH)
    end

    local diffZ = math.abs(targetZ - currentZ)
    for i = 1, diffZ do
        while not turtle.forward() do
            turtle.dig()
        end
    end
end

-- Check if block above is higher than target Y
function checkHeight(targetY, currentY)
    local success, data = turtle.inspectUp()
    return success and currentY > targetY
end

-- Main flattening function
function flatten(targetY, polyX, polyZ)
    -- Ensure we have fuel
    if not checkFuel() then
        print("Not enough fuel!")
        return
    end

    -- Get current position (assuming starting position is known)
    local currentX, currentY, currentZ = 0, 0, 0

    -- Find bounding box of polygon
    local minX = math.min(table.unpack(polyX))
    local maxX = math.max(table.unpack(polyX))
    local minZ = math.min(table.unpack(polyZ))
    local maxZ = math.max(table.unpack(polyZ))

    print("Starting flattening operation...")
    print("Target Y level: " .. targetY)
    print("Area: " .. minX .. "," .. minZ .. " to " .. maxX .. "," .. maxZ)

    -- Main flattening loop
    for x = minX, maxX do
        for z = minZ, maxZ do
            -- Only process if point is inside polygon
            if isPointInPolygon(x, z, polyX, polyZ) then
                -- Move to current coordinate
                moveToCoord(x, z, currentX, currentZ)
                currentX, currentZ = x, z

                -- Check and dig above blocks
                while checkHeight(targetY, currentY) do
                    turtle.digUp()
                    turtle.up()
                    currentY = currentY + 1
                end

                -- Return to target Y level
                while currentY > targetY do
                    turtle.down()
                    currentY = currentY - 1
                end
            end
        end
    end

    print("Returning to starting position...")
    -- Return to starting position
    moveToCoord(0, 0, currentX, currentZ)
    turnToDirection(DIRECTIONS.SOUTH) -- Return to initial direction
    print("Flattening complete!")
end

-- Parse command line arguments
local args = {...}
if #args ~= 9 then
    print("Usage: flatten <targetY> <x1> <z1> <x2> <z2> <x3> <z3> <x4> <z4>")
    return
end

local targetY = tonumber(args[1])
local polyX = {tonumber(args[2]), tonumber(args[4]), tonumber(args[6]), tonumber(args[8])}
local polyZ = {tonumber(args[3]), tonumber(args[5]), tonumber(args[7]), tonumber(args[9])}

flatten(targetY, polyX, polyZ)
