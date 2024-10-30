-- Coordinates for tracking the turtle's position
local x, y, z = 0, 0, 0


local direction = 0  -- 0 = North, 1 = East, 2 = South, 3 = West

-- Function to initialize the turtle
local function init()
    print("Turtle initialization started.")

    -- Check if turtle has enough fuel
    if turtle.getFuelLevel() < 100 then
        print("Low fuel. Please refuel the turtle.")
        return false  -- Abort initialization
    end

    print("Turtle initialized with enough fuel.")
    return true  -- Initialization successful
end

-- Function to move the turtle forward and update its coordinates
local function moveForward()
    if turtle.forward() then
        if direction == 0 then z = z + 1
        elseif direction == 1 then x = x + 1
        elseif direction == 2 then z = z - 1
        elseif direction == 3 then x = x - 1
        end
        return true  -- Move was successful
    else
        print("Failed to move forward.")
        return false  -- Move failed
    end
end

-- Function to turn right and update direction
local function turnRight()
    turtle.turnRight()
    direction = (direction + 1) % 4
    return true  -- Turn successful
end

-- Function to turn left and update direction
local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 1 + 4) % 4
    return true  -- Turn successful
end

-- Function to dig forward and return if successful
local function digForward()
    while turtle.detect() do
        if turtle.dig() then
            print("Block dug successfully.")
        else
            print("Failed to dig block.")
            return false
        end
    end
    return true
end

-- Function to search for diamonds
local function mineForDiamonds()
    while true do
        -- Check if the block in front contains diamonds
        if turtle.inspect() then
            local success, block = turtle.inspect()
            if success and block.name == "minecraft:diamond_ore" then
                print("Diamond ore found!")
                if not turtle.dig() then
                    print("Failed to mine diamond ore.")
                    return false
                end
            end
        end

        -- Dig and move forward
        if not digForward() or not moveForward() then
            print("Unable to proceed, stopping mining.")
            return false
        end

        -- Check fuel level
        if turtle.getFuelLevel() < 50 then
            print("Low fuel, returning to start.")
            return returnHome()  -- Call returnHome if fuel is low
        end

        -- Sleep to prevent too rapid execution
        sleep(0.5)
    end
    return true
end

-- Function to return home by retracing steps
local function returnHome()
    print("Returning to home base...")
    -- Retrace steps along the Z axis
    while z > 0 do
        turnAroundIfNeeded(2) -- Face South
        if not moveForward() then
            print("Failed to return home.")
            return false
        end
        z = z - 1
    end

    -- Retrace steps along the X axis
    while x > 0 do
        turnAroundIfNeeded(3) -- Face West
        if not moveForward() then
            print("Failed to return home.")
            return false
        end
        x = x - 1
    end

    print("Turtle returned home.")
    return true
end

-- Helper to turn in the correct direction
local function turnAroundIfNeeded(targetDirection)
    while direction ~= targetDirection do
        turnRight()
    end
end

-- Function to refuel the turtle
local function refuel()
    print("Refueling...")
    -- Insert logic to refuel, for example:
    if turtle.getFuelLevel() < turtle.getFuelLimit() then
        turtle.refuel(1)
        return true
    else
        print("Fuel is sufficient.")
        return false
    end
end

-- Main script execution
if init() then
    print("Starting mining operation...")
    if not mineForDiamonds() then
        print("Mining operation failed. Turtle might have returned home.")
    else
        print("Mining operation completed successfully.")
        returnHome()  -- Return home after mining completes
    end
else
    print("Initialization failed.")
end
