-- 3D Mining Turtle Script with Custom Return Location

-- Set the original location here
local originalX = 0  -- Change this to your desired X coordinate
local originalY = 0  -- Change this to your desired Y coordinate
local originalZ = 0  -- Change this to your desired Z coordinate

-- Initialize current position and orientation
local x, y, z = originalX, originalY, originalZ
local orientation = 0 -- 0: +x, 1: +z, 2: -x, 3: -z

-- Function to update position based on movement
local function updatePosition(success)
    if success then
        if orientation == 0 then x = x + 1
        elseif orientation == 1 then z = z + 1
        elseif orientation == 2 then x = x - 1
        else z = z - 1 end
    end
end

-- Function to turn the turtle
local function turn(direction)
    if direction == "right" then
        turtle.turnRight()
        orientation = (orientation + 1) % 4
    else
        turtle.turnLeft()
        orientation = (orientation - 1) % 4
    end
end

-- Function to move forward
local function forward()
    local success = turtle.forward()
    updatePosition(success)
    return success
end

-- Function to move up
local function up()
    local success = turtle.up()
    if success then y = y + 1 end
    return success
end

-- Function to move down
local function down()
    local success = turtle.down()
    if success then y = y - 1 end
    return success
end

-- Function to check if inventory is full
local function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

-- Function to return home
local function returnHome()
    -- Move in X direction
    local targetOrientation = (x < originalX) and 0 or 2
    while orientation ~= targetOrientation do
        turn("right")
    end
    while x ~= originalX do
        if not forward() then
            turtle.dig()
        end
    end
    
    -- Move in Z direction
    targetOrientation = (z < originalZ) and 1 or 3
    while orientation ~= targetOrientation do
        turn("right")
    end
    while z ~= originalZ do
        if not forward() then
            turtle.dig()
        end
    end
    
    -- Move in Y direction
    while y < originalY do
        if not up() then
            turtle.digUp()
        end
    end
    while y > originalY do
        if not down() then
            turtle.digDown()
        end
    end
    
    -- Face original direction
    while orientation ~= 0 do
        turn("right")
    end
end

-- Function to mine a 3x3 tunnel
local function mineTunnel()
    -- Dig forward
    turtle.dig()
    forward()
    
    -- Dig up and down
    turtle.digUp()
    turtle.digDown()
    
    -- Mine right column
    turn("right")
    turtle.dig()
    turtle.digUp()
    turtle.digDown()
    
    -- Mine top-right and center-right
    turn("left")
    up()
    turn("right")
    turtle.dig()
    up()
    turtle.dig()
    
    -- Move to left column
    turn("left")
    down()
    down()
    turn("left")
    forward()
    
    -- Mine left column
    turtle.dig()
    turtle.digUp()
    turtle.digDown()
    
    -- Return to center
    turn("right")
    forward()
    turn("right")
end

-- Main function
local function main()
    local targetX = -53
    local distance = math.abs(targetX - x)

    -- Check if we have enough fuel
    if turtle.getFuelLevel() < distance * 2 + 500 then
        print("Not enough fuel. Please refuel.")
        return
    end

    print("Starting position: X=" .. x .. ", Y=" .. y .. ", Z=" .. z)
    print("Target X: " .. targetX)
    print("Return position: X=" .. originalX .. ", Y=" .. originalY .. ", Z=" .. originalZ)

    -- Travel to target location and mine
    print("Traveling and mining to target location...")
    while x > targetX do
        mineTunnel()
        if isInventoryFull() or turtle.getFuelLevel() <= 500 then
            print("Inventory full or low fuel. Returning home...")
            returnHome()
            print("Mining operation completed.")
            return
        end
    end

    -- Return home
    print("Reached target. Returning home...")
    returnHome()

    print("Mining operation completed.")
end

-- Run the main function
main()