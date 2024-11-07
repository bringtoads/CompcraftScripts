-- Constants for directions
local DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}

-- Position tracking
local position = {
    x = 0,
    y = 0,
    z = 0
}

-- Helper functions for movement and direction
local function updatePosition(direction)
    if direction == DIRECTIONS.SOUTH then
        position.z = position.z + 1
    elseif direction == DIRECTIONS.WEST then
        position.x = position.x - 1
    elseif direction == DIRECTIONS.NORTH then
        position.z = position.z - 1
    elseif direction == DIRECTIONS.EAST then
        position.x = position.x + 1
    end
end

local function turnRight(currentDirection)
    turtle.turnRight()
    return (currentDirection + 1) % 4
end

local function turnLeft(currentDirection)
    turtle.turnLeft()
    local newDirection = (currentDirection - 1) % 4
    if newDirection < 0 then
        newDirection = newDirection + 4
    end
    return newDirection
end

-- Enhanced mining function with fuel checking and error handling
function mineArea(length, height, width)
    -- Parameter validation
    if not (length and height and width) then
        print("Error: All dimensions must be provided")
        return false
    end

    if length <= 0 or height <= 0 or width <= 0 then
        print("Error: Dimensions must be positive numbers")
        return false
    end

    -- Calculate required fuel (with safety margin)
    local requiredFuel = (length * width * height) * 2 -- Approximate fuel needed
    if turtle.getFuelLevel() < requiredFuel then
        print("Warning: Not enough fuel! Need at least " .. requiredFuel .. " fuel")
        return false
    end

    local direction = DIRECTIONS.SOUTH
    local layerComplete = false

    -- Mine in layers
    for y = 1, height do
        -- Mine each layer in a snake pattern
        for x = 1, length do
            -- Mine forward for the width
            for z = 1, width - 1 do
                turtle.dig()
                if not turtle.forward() then
                    print("Error: Path blocked at x:" .. x .. " y:" .. y .. " z:" .. z)
                    return false
                end
                updatePosition(direction)
            end

            -- Turn for next strip if not at the end
            if x < length then
                if layerComplete then
                    direction = turnLeft(direction)
                    turtle.dig()
                    if not turtle.forward() then
                        return false
                    end
                    updatePosition(direction)
                    direction = turnLeft(direction)
                else
                    direction = turnRight(direction)
                    turtle.dig()
                    if not turtle.forward() then
                        return false
                    end
                    updatePosition(direction)
                    direction = turnRight(direction)
                end
                layerComplete = not layerComplete
            end
        end

        -- Move up for next layer if not at top
        if y < height then
            turtle.digUp()
            if not turtle.up() then
                print("Error: Cannot move up to next layer")
                return false
            end
            position.y = position.y + 1
        end
    end

    print("Mining complete!")
    print(string.format("Final position - X: %d, Y: %d, Z: %d", position.x, position.y, position.z))
    return true
end

-- Example usage:
-- mineArea(5, 3, 4)  -- This will mine a 5x3x4 area (length x height x width)
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

mineArea(x, y, z)
