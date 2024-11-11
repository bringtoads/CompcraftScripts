--[[
Turtle Control Script with HTTP Polling
This script allows a Minecraft Turtle (from the ComputerCraft mod) to communicate
with an ASP.NET Core Web API server using HTTP polling. The turtle can receive
commands from the server and execute them
--]] -- It's time for the rise of the planets of turtles, Turtles togethre strong
-- Don't know why I am doing it but here we are
-- place turtle direction south
---------------------------------------------------
---------------------  S  -------------------------
---------------------  Z+ -------------------------
-----  E  ---------------------------- W-  --------
-----  X+  ------------0-------------- X-  --------
---------------------------------------------------
---------------------  N  -------------------------
---------------------  Z- -------------------------
---------------------------------------------------
-- direction direction
-- (forward z+)  south = 0
-- (right x-)    west = 1
-- (backward z-) north = 2
-- (left x+)     east  = 3
-- (up y+) = 4
-- (donw y-) = 5
-------------------------------------------Constants---------------------------------------------------------
local DIRECTIONS = {
    SOUTH = 0,
    WEST = 1,
    NORTH = 2,
    EAST = 3
}
local STATUS = {
    IDLE = "idle",
    MINING = "mining",
    STOPPED = "stopped",
    RUNNING = "running"
}
local HOME_COORDINATES = {
    x = 0,
    y = 0,
    z = 0
}

local ORE_LEVELS = {
    Diamonds = -53,
    Netherite = 15
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

local turtlesUrl = "http://localhost:5041/api/turtles/" -- Replace with your actual server URL
-- local turtlesUrl = "https://turtleserver-production.up.railway.app/api/turtles/" -- Replace with your actual server URL
local turtleId = os.getComputerID()
local direction = DIRECTIONS.SOUTH
local turtleName = nil
local turtleStatus = STATUS.IDLE
local turtleFuelLevel = 0
local turtleInventory = {}

local dropChestPos = {
    x = 0,
    y = 0,
    z = 0
}
------------------------------Turtle Functions----------------------------------------------------------------
---made a separate logger to comment out later
local function logger(data)
    print(data)
end
-- if gps is connected gets the current cordinates the turtle
-- returns true and sets postion to gps cordinates if gps is available
-- returns false and sets position to 0,0,
local function getCurrentCordinates()
    -- Check if GPS is available
    if gps and gps.locate then
        gpsPos.x, gpsPos.y, gpsPos.z = gps.locate()
        if gpsPos.x and gpsPos.y and gpsPos.z then
            position.x = gpsPos.x
            position.y = gpsPos.y
            position.z = gpsPos.z
            return true
        else
            -- If GPS coordinates could not be obtained, leave it at (0, 0, 0)
            print("GPS coordinates not found. Position remains at: (0, 0, 0)")
            return false
        end
    else
        print("GPS is not available. Position remains at: (0, 0, 0)")
        return false
    end
end

-- if gps is connected updates the direction direction using gps
local function getFacingDirection()
    -- Get the initial coordinates
    local status = getCurrentCordinates()
    if status then
        turtle.forward() -- Move forward to determine the direction
        local tempx, tempy, tempz = gps.locate()
        turtle.back() -- Move back to the original position

        -- Determine direction based on the change in coordinates
        if tempx < position.x then
            direction = DIRECTIONS.EAST
        elseif tempx > position.x then
            direction = DIRECTIONS.WEST
        elseif tempz > position.z then
            direction = DIRECTIONS.SOUTH
        elseif tempz < position.z then
            direction = DIRECTIONS.NORTH
        end
    else
        print("Error: Unable to get current coordinates")
    end
end
-- Function to update the turtle's position based on movement
local function updatePosition()
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

-- Function to gather the turtle's inventory
local function getTurtleInventory()
    local turtleInventory = {} -- Initialize turtleInventory inside the function

    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            table.insert(turtleInventory, {
                BlockName = item.name,
                BlockCount = item.count,
                Slot = slot
            })
        end
    end

    -- If no items were found, add an empty entry
    if #turtleInventory == 0 then
        table.insert(turtleInventory, {
            BlockName = "empty",
            BlockCount = 0,
            Slot = 0
        })
    end

    return turtleInventory
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

-- Function to getfuel Level
local function getFuelLevel()
    turtleFuelLevel = turtle.getFuelLevel()
end

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
local function turnBack()
    turnRight()
    turnRight()
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
    turnBack()
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

-----don't know what this is but it is what it is---------------------------------------------
-----this will check if there is block to dig and if turtle can move  else print can't move ---
local function digAndMoveForward()
    if turtle.dig() then
        forward()
    else
        print("No block forward, just moving forward")
        forward()
    end
end
local function digAndMoveBackward()
    turtle.turnRight()
    direction = (direction + 1) % 4
    turtle.turnRight()
    direction = (direction + 1) % 4
    if turtle.dig() then
        forward()
    else
        print("No block back, just moving back")
        forward()
    end
end
local function digAndMoveUp()
    if turtle.digUp() then
        up()
    else
        print("No block up, just moving forward")
        up()
    end
end
local function digAndMoveDown()
    if turtle.digDown() then
        down()
    else
        print("No block down, just moving down")
        down()
    end
end
local function digAndMoveRight()
    turnRight()
    if turtle.dig() then
        forward()
    else
        print("No block right, just moving right")
        forward()
    end
end
local function digAndMoveLeft()
    turnLeft()
    if turtle.dig() then
        forward()
    else
        print("No block left, just moving left")
        forward()
    end
end
-----------------------------------------TransFormation functions----------------------------------------
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
-----------------------------------------Custom Functions----------------------------
-- Function to return to home coordinates
local function returnHome()
    -- Move vertically to home Y level
    while position.y < HOME_COORDINATES.y do
        moveUp()
    end
    while position.y > HOME_COORDINATES.y do
        moveDown()
    end

    -- Move horizontally to home X coordinate
    if position.x > HOME_COORDINATES.x then
        while direction ~= DIRECTIONS.WEST do
            turnLeft()
        end
        moveForward(position.x - HOME_COORDINATES.x)
    elseif position.x < HOME_COORDINATES.x then
        while direction ~= DIRECTIONS.EAST do
            turnLeft()
        end
        moveForward(HOME_COORDINATES.x - position.x)
    end

    -- Move horizontally to home Z coordinate
    if position.z > HOME_COORDINATES.z then
        while direction ~= DIRECTIONS.NORTH do
            turnLeft()
        end
        moveForward(position.z - HOME_COORDINATES.z)
    elseif position.z < HOME_COORDINATES.z then
        while direction ~= DIRECTIONS.SOUTH do
            turnLeft()
        end
        moveForward(HOME_COORDINATES.z - position.z)
    end

    print("Returned home to coordinates: X=" .. HOME_COORDINATES.x .. ", Y=" .. HOME_COORDINATES.y .. ", Z=" ..
              HOME_COORDINATES.z)
end
------------------------------------------------------------------------G---------------------------------

-- function mining a certain block x y z needed
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

------------------------------------------------Main---------------------------------------------------------
-- Main section for the turtle start
local currentCommand = nil -- Store the current command
local commandMiningParams = {
    x = 0,
    y = 0,
    z = 0
}

-- Function to Register Turtle in the backend
local function registerTurtle()
    print("Registering turtle")
    -- getting current cordinates
    getCurrentCordinates()
    -- Fetching the turtle's inventory and other necessary data
    turtleInventory = getTurtleInventory()
    local dataToSend = {
        InGameId = turtleId,
        CurrentPosition = position,
        FuelLevel = turtleFuelLevel,
        Inventory = turtleInventory,
        Status = turtleStatus
    }
    -- Serialize the table to JSON
    local jsonData = textutils.serializeJSON(dataToSend)
    -- logger(jsonData)
    local url = turtlesUrl .. "register"

    -- Prepare the headers
    local headers = {
        ["Content-Type"] = "application/json"
    }

    -- Use http.request to include headers
    local response, err = http.post(url, jsonData, headers)
    -- Read the response data
    local responseData = response.readAll()
    response.close()

    if responseData then
        -- logger(responseData)
        -- Deserialize the JSON response
        local responseTable = textutils.unserializeJSON(responseData)
        -- Check if the name field exists in the response
        if responseTable then
            local Success = responseTable.success
            local data = responseTable.data
            local message = responseTable.message

            if (Success) then
                turtleName = data.name
                if (message == "registered") then
                    os.setComputerLabel(turtleName)
                    print("Turtle registered with Name: " .. turtleName)
                else
                    print("Welcome back " .. turtleName .. " get back to slaving")
                end
            else
                print("something went wrong it's time for pida")
            end
        else
            print("Failed to retrieve turtle Name from server response")
        end
    else
        print("Failed to retrieve response from server")
    end
end
local function get()
end
-- Function to get the next command from the server for this turtle
local function getNextCommand(turtleId)
    local commandUrl = turtlesUrl .. turtleId .. "/next-command"
    local response = http.get(commandUrl)
    -- Check if the response is nil or false (indicating an error)
    if not response then
        return nil
    end

    local commandData = response.readAll()
    response.close()
    if commandData then
        -- print("Received command data: " .. commandData)
        return textutils.unserializeJSON(commandData)
    end

    return nil
end

-- Function to poll the server for new commands
local function pollForCommands()
    while true do
        local commandResponse = getNextCommand(turtleId)

        -- if request is not No block right, just moving right
        if commandResponse ~= nil then
            local response = commandResponse.command
            local success = response.success
            local message = response.message
            local resObj = response.data
            logger("response:")
            logger(response)
            logger("---------")
            logger("success:")
            logger(success)
            logger("---------")
            logger("message:")
            logger(message)
            logger("---------")
            logger("resObj:")
            logger(resObj)
            logger("------------------")
            logger("mining dimenxion x:")
            logger()
            logger("---------")
            currentCommand = resObj
            if success then
                if commandResponse.miningDimensions then
                    commandMiningParams.x = response.data.miningDimensions.x
                    commandMiningParams.y = response.data.miningDimensions.y
                    commandMiningParams.z = response.data.miningDimensions.z

                    logger("Mining Dimensions:" .. commandMiningParams.x .. commandMiningParams.y ..
                               commandMiningParams.z)
                else
                    commandMiningParams = {}
                end
            end
        end
        sleep(3)
    end
end

-- Function to execute the current command
local function executeCommands()
    while true do
        if currentCommand == "forward" then
            forward()
            currentCommand = nil
        elseif currentCommand == "backward" then
            backward()
            currentCommand = nil
        elseif currentCommand == "right" then
            right()
            currentCommand = nil
        elseif currentCommand == "left" then
            left()
            currentCommand = nil
        elseif currentCommand == "up" then
            up()
            currentCommand = nil
        elseif currentCommand == "down" then
            down()
            currentCommand = nil
        elseif currentCommand == "returnHome" then
            print("Returning home...")
            returnHome()
        elseif currentCommand == "mine" then
            mine(commandMiningParams.x, commandMiningParams.y, commandMiningParams.z)
            currentCommand = nil
        elseif currentCommand == nil then
            sleep(1) -- Wait if there are no commands
        end
    end
end

-- function to print low fuel warning if no fuel or low fuel
local function showLowFuelWarning()
    if (turtleFuelLevel < 50) then
        print("runninng low on fooodd, help a man out")
    elseif turtleFuelLevel == 0 then
        print("no fuel, need foooooooodd")
    end
end

-- main init
local function init()
    print("Initializing Bot")
    getFuelLevel()
    getFacingDirection()
    showLowFuelWarning()
    registerTurtle()
    parallel.waitForAll(pollForCommands, executeCommands)
end

init()

---------------------------------------------------------------------------------------------------------
