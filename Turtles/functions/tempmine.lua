local direction = 0 -- 0: South, 1: West, 2: North, 3: East
local x, y, z = gps.locate()
print("Starting position - X: " .. x .. " Y: " .. y .. " Z: " .. z)

local _DirectionLog = {
    x = x,
    y = y,
    z = z
}

local chestDirection = {
    x = 2216,
    y = -53,
    z = -83
}

local function faceDirection(targetDirection)
    while direction ~= targetDirection do
        turtle.turnRight()
        direction = (direction + 1) % 4
    end
end

local function updatePosition()
    if direction == 0 then
        _DirectionLog.z = _DirectionLog.z + 1
    elseif direction == 1 then
        _DirectionLog.x = _DirectionLog.x - 1
    elseif direction == 2 then
        _DirectionLog.z = _DirectionLog.z - 1
    elseif direction == 3 then
        _DirectionLog.x = _DirectionLog.x + 1
    end
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

local function isInventoryFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

local function moveForward()
    turtle.forward()
    print("moved forward")
    updatePosition()
    -- if turtle.forward() then
    --   turtle.forward()
    --     updatePosition()

    --     return true
    -- else
    --     print("shit happening")
    --     turtle.forward()
    --     return false
    -- end
end

local function goTo(xTarget, zTarget)
    -- Move along Z-axis first
    if _DirectionLog.z < zTarget then
        faceDirection(0)
        while _DirectionLog.z < zTarget do
            if moveForward() then
                _DirectionLog.z = _DirectionLog.z + 1
            end
        end
    elseif _DirectionLog.z > zTarget then
        faceDirection(2)
        while _DirectionLog.z > zTarget do
            if moveForward() then
                _DirectionLog.z = _DirectionLog.z - 1
            end
        end
    end

    -- Move along X-axis
    if _DirectionLog.x < xTarget then
        faceDirection(3)
        while _DirectionLog.x < xTarget do
            if moveForward() then
                _DirectionLog.x = _DirectionLog.x + 1
            end
        end
    elseif _DirectionLog.x > xTarget then
        faceDirection(1)
        while _DirectionLog.x > xTarget do
            if moveForward() then
                _DirectionLog.x = _DirectionLog.x - 1
            end
        end
    end
end

local function dumpItems()
    for slot = 1, 16 do
        turtle.select(slot)
        turtle.dropDown() -- Make sure the chest is below the turtle
    end
end

local function returnHome()
    print("returning home")
    local curX, curY, curZ = gps.locate()
    print("Returning to chest - Current position: X: " .. curX .. " Y: " .. curY .. " Z: " .. curZ)

    goTo(chestDirection.x, chestDirection.z)
    dumpItems()
    faceDirection(0) -- Face south after dumping
end

while true do
    print("it is running bitches")
    while not isInventoryFull() do
        turtle.dig()
        moveForward()
    end

    returnHome()

    -- After dumping items, go back to the last position and resume mining
    print("Resuming mining at position: X: " .. _DirectionLog.x .. " Z: " .. _DirectionLog.z)
    goTo(_DirectionLog.x, _DirectionLog.z)
end
