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

-- local turtlesUrl = "http://localhost:5041/api/turtles/" -- Replace with your actual server URL
local turtlesUrl = "https://turtleserver-production.up.railway.app/api/turtles/" -- Replace with your actual server URL
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

-- Main mining function
--   local function mineVolume(length, width, height)
--     -- Function to check and refuel if needed
--     local function checkFuel(blocksNeeded)
--         local currentFuel = turtle.getFuelLevel()
--         if currentFuel == "unlimited" then
--             return true
--         end

--         -- Calculate fuel needed (blocks to mine + return journey)
--         local fuelNeeded = blocksNeeded + 100 -- Adding buffer for return journey

--         if currentFuel < fuelNeeded then
--             for i = 1, 16 do
--                 turtle.select(i)
--                 if turtle.refuel(0) then
--                     turtle.refuel(64)
--                     if turtle.getFuelLevel() >= fuelNeeded then
--                         return true
--                     end
--                 end
--             end
--             return false
--         end
--         return true
--     end

--     -- Function to return to starting position
--     local function returnToStart(length, width, height)
--         -- Turn around
--         turtle.turnRight()
--         turtle.turnRight()

--         -- Return to ground level
--         for i = 1, height - 1 do
--             turtle.down()
--         end

--         -- Return to start position
--         for i = 1, length - 1 do
--             turtle.forward()
--         end

--         -- Return to first row
--         turtle.turnRight()
--         for i = 1, width - 1 do
--             turtle.forward()
--         end

--         -- Face original direction
--         turtle.turnLeft()
--     end

--     logger("length:" .. length .. " width:" .. width .. " height:" .. height)
--     -- Calculate total blocks for fuel check
--     local totalBlocks = length * width * height

--     -- Check if we have enough fuel
--     if not checkFuel(totalBlocks * 2) then -- *2 for safety margin
--         print("Not enough fuel! Need at least " .. totalBlocks * 2 .. " fuel.")
--         return false
--     end

--     print("Starting mining operation: " .. length .. "x" .. width .. "x" .. height)

--     -- For each level
--     for h = 1, height do
--         -- For each width row
--         for w = 1, width do
--             -- Mine forward for length
--             for l = 1, length do
--                 turtle.dig()
--                 if l < length then
--                     turtle.forward()
--                 end
--             end

--             -- If not at last width, prepare for next row
--             if w < width then
--                 if w % 2 == 1 then
--                     turtle.turnRight()
--                     turtle.dig()
--                     turtle.forward()
--                     turtle.turnRight()
--                 else
--                     turtle.turnLeft()
--                     turtle.dig()
--                     turtle.forward()
--                     turtle.turnLeft()
--                 end
--             end
--         end

--         -- If not at top level, move up and reset position
--         if h < height then
--             -- Return to start of level if at even width
--             if width % 2 == 0 then
--                 returnToStart(length, width, 1)
--             end

--             -- Move up
--             turtle.digUp()
--             turtle.up()

--             -- If at even width, need to turn around
--             if width % 2 == 0 then
--                 turtle.turnRight()
--                 turtle.turnRight()
--             end
--         end
--     end

--     -- Return to starting position
--     if width % 2 == 0 and height % 2 == 1 then
--         -- If both width is even and height is odd, we're direction wrong way
--         returnToStart(length, width, height)
--     elseif width % 2 == 1 and height % 2 == 0 then
--         -- If width is odd and height is even, we're direction wrong way
--         returnToStart(length, width, height)
--     end

--     print("Mining operation completed!")
--     return true
-- end

-- mining using path finding ----------

-- local position = {
--     x = 0,
--     y = 0,
--     z = 0
-- } -- Relative to start
-- local direction = 0 -- 0=north, 1=east, 2=south, 3=west

-- local knownBlocks = {} -- Store known empty spaces and obstacles

-- -- Constants
-- local INVENTORY_SLOTS = 16
-- local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
-- local DIRECTIONS = {
--     [NORTH] = {
--         x = 0,
--         z = -1
--     },
--     [EAST] = {
--         x = 1,
--         z = 0
--     },
--     [SOUTH] = {
--         x = 0,
--         z = 1
--     },
--     [WEST] = {
--         x = -1,
--         z = 0
--     }
-- }

-- -- Helper function to get block key for knownBlocks table
-- local function getBlockKey(x, y, z)
--     return x .. "," .. y .. "," .. z
-- end

-- -- Update known blocks map
-- local function updateKnownBlock(x, y, z, isBlocked)
--     knownBlocks[getBlockKey(x, y, z)] = isBlocked
-- end

-- -- Check if position is known to be blocked
-- local function isBlocked(x, y, z)
--     local key = getBlockKey(x, y, z)
--     return knownBlocks[key] == true
-- end

-- -- Update current position after movement
-- local function updatePosition(success)
--     if success then
--         local dir = DIRECTIONS[direction]
--         position.x = position.x + (dir.x or 0)
--         position.z = position.z + (dir.z or 0)
--     end
-- end

-- -- Basic movement functions with position tracking
-- local function forward()
--     local success = turtle.forward()
--     updatePosition(success)
--     return success
-- end

-- local function up()
--     local success = turtle.up()
--     if success then
--         position.y = position.y + 1
--     end
--     return success
-- end

-- local function down()
--     local success = turtle.down()
--     if success then
--         position.y = position.y - 1
--     end
--     return success
-- end

-- local function turnLeft()
--     turtle.turnLeft()
--     direction = (direction - 1) % 4
-- end

-- local function turnRight()
--     turtle.turnRight()
--     direction = (direction + 1) % 4
-- end

-- -- A* pathfinding implementation
-- local function manhattan3D(x1, y1, z1, x2, y2, z2)
--     return math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1)
-- end

-- local function getNeighbors(x, y, z)
--     local neighbors = {}
--     local offsets = {{
--         x = 0,
--         y = 1,
--         z = 0
--     }, -- up
--     {
--         x = 0,
--         y = -1,
--         z = 0
--     }, -- down
--     {
--         x = 1,
--         y = 0,
--         z = 0
--     }, -- east
--     {
--         x = -1,
--         y = 0,
--         z = 0
--     }, -- west
--     {
--         x = 0,
--         y = 0,
--         z = 1
--     }, -- south
--     {
--         x = 0,
--         y = 0,
--         z = -1
--     } -- north
--     }

--     for _, offset in ipairs(offsets) do
--         local newX = x + offset.x
--         local newY = y + offset.y
--         local newZ = z + offset.z

--         -- Check if position is valid and not blocked
--         if not isBlocked(newX, newY, newZ) then
--             table.insert(neighbors, {
--                 x = newX,
--                 y = newY,
--                 z = newZ
--             })
--         end
--     end

--     return neighbors
-- end

-- local function findPath(startX, startY, startZ, targetX, targetY, targetZ)
--     local openSet = {}
--     local closedSet = {}
--     local cameFrom = {}
--     local gScore = {}
--     local fScore = {}

--     -- Initialize start node
--     local startNode = getBlockKey(startX, startY, startZ)
--     openSet[startNode] = true
--     gScore[startNode] = 0
--     fScore[startNode] = manhattan3D(startX, startY, startZ, targetX, targetY, targetZ)

--     while next(openSet) do
--         -- Find node with lowest fScore
--         local current = nil
--         local lowestF = math.huge
--         for node in pairs(openSet) do
--             if fScore[node] < lowestF then
--                 current = node
--                 lowestF = fScore[node]
--             end
--         end

--         -- Check if we reached the target
--         if current == getBlockKey(targetX, targetY, targetZ) then
--             local path = {}
--             while current do
--                 local x, y, z = current:match("(-?%d+),(-?%d+),(-?%d+)")
--                 table.insert(path, 1, {
--                     x = tonumber(x),
--                     y = tonumber(y),
--                     z = tonumber(z)
--                 })
--                 current = cameFrom[current]
--             end
--             return path
--         end

--         -- Move current node from open to closed set
--         openSet[current] = nil
--         closedSet[current] = true

--         -- Get x, y, z from current node key
--         local x, y, z = current:match("(-?%d+),(-?%d+),(-?%d+)")
--         x, y, z = tonumber(x), tonumber(y), tonumber(z)

--         -- Check neighbors
--         for _, neighbor in ipairs(getNeighbors(x, y, z)) do
--             local neighborKey = getBlockKey(neighbor.x, neighbor.y, neighbor.z)

--             if not closedSet[neighborKey] then
--                 local tentativeG = gScore[current] + 1

--                 if not openSet[neighborKey] then
--                     openSet[neighborKey] = true
--                 elseif tentativeG >= gScore[neighborKey] then
--                     goto continue
--                 end

--                 cameFrom[neighborKey] = current
--                 gScore[neighborKey] = tentativeG
--                 fScore[neighborKey] = gScore[neighborKey] +
--                                           manhattan3D(neighbor.x, neighbor.y, neighbor.z, targetX, targetY, targetZ)
--             end

--             ::continue::
--         end
--     end

--     return nil -- No path found
-- end

-- -- Inventory management
-- local function isInventoryFull()
--     for slot = 1, INVENTORY_SLOTS do
--         if turtle.getItemCount(slot) == 0 then
--             return false
--         end
--     end
--     return true
-- end

-- -- Function to navigate to a specific position
-- local function navigateToPosition(targetX, targetY, targetZ)
--     local path = findPath(position.x, position.y, position.z, targetX, targetY, targetZ)
--     if not path then
--         print("No path found!")
--         return false
--     end

--     -- Follow the path
--     for i = 2, #path do -- Start from 2 as 1 is current position
--         local node = path[i]
--         local dx = node.x - position.x
--         local dy = node.y - position.y
--         local dz = node.z - position.z

--         -- Handle vertical movement first
--         if dy > 0 then
--             up()
--         elseif dy < 0 then
--             down()
--         end

--         -- Handle horizontal movement
--         if dx ~= 0 or dz ~= 0 then
--             -- Calculate target direction
--             local targetFacing
--             if dx > 0 then
--                 targetFacing = EAST
--             elseif dx < 0 then
--                 targetFacing = WEST
--             elseif dz > 0 then
--                 targetFacing = SOUTH
--             else
--                 targetFacing = NORTH
--             end

--             -- Turn to face target direction
--             while direction ~= targetFacing do
--                 turnRight()
--             end

--             -- Move forward
--             forward()
--         end
--     end

--     return true
-- end

-- -- Function to return to chest and deposit items
-- local function returnToChestAndDeposit()
--     -- Navigate back to position above chest
--     if not navigateToPosition(dropChestPos.x, dropChestPos.y, dropChestPos.z) then
--         print("Failed to find path back to chest!")
--         return false
--     end

--     -- Deposit items
--     down() -- Move down to chest level
--     for slot = 1, INVENTORY_SLOTS do
--         turtle.select(slot)
--         turtle.dropDown()
--     end
--     up() -- Move back up

--     return true
-- end

-- -- Main mining function with inventory management
-- function smartMine(length, width, height)
--     -- Initialize starting position
--     -- dropChestPos.x = position.x
--     -- dropChestPos.y = position.y
--     -- dropChestPos.z = position.z
--     -- local tempPos = {}

--     -- Main mining loop
--     for h = 1, height do
--         for w = 1, width do
--             for l = 1, length do
--                 -- Check inventory before mining
--                 if isInventoryFull() then
--                     print("Inventory full, returning to chest...")
--                     returnToChestAndDeposit()
--                     print("Returning to mining position...")
--                     navigateToPosition(position.x, position.y, position.z)
--                 end

--                 -- Mine and move
--                 turtle.dig()
--                 if l < length then
--                     forward()
--                     -- Update known blocks
--                     updateKnownBlock(position.x, position.y, position.z, false)
--                 end
--             end

--             -- Handle width movement
--             if w < width then
--                 if w % 2 == 1 then
--                     turnRight()
--                     turtle.dig()
--                     forward()
--                     turnRight()
--                 else
--                     turnLeft()
--                     turtle.dig()
--                     forward()
--                     turnLeft()
--                 end
--                 updateKnownBlock(position.x, position.y, position.z, false)
--             end
--         end

--         -- Handle height movement
--         if h < height then
--             turtle.digUp()
--             up()
--             updateKnownBlock(position.x, position.y, position.z, false)

--             -- Reset position for next layer
--             if width % 2 == 0 then
--                 turnRight()
--                 turnRight()
--             end
--         end
--     end

--     -- Return to chest after mining is complete
--     print("Mining complete, returning to chest...")
--     returnToChestAndDeposit()
--     print("Operation completed successfully!")
-- end

-- mining using path finding

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
        print("No command data received.")
        return nil
    end

    local commandData = response.readAll()
    response.close()
    logger(commandData)
    if commandData then
        -- print("Received command data: " .. commandData)
        return textutils.unserializeJSON(commandData)
    else
        print("No command data received.")
    end

    return nil
end

-- Function to poll the server for new commands
local function pollForCommands()
    while true do
        local commandResponse = getNextCommand(turtleId)
        logger(commandResponse)

        -- if request is not No block right, just moving right
        if commandResponse ~= nil then
            local response = commandResponse.command
            local success = response.success
            local message = response.message
            local resObj = response.data
            currentCommand = resObj
            if success then
                if commandResponse.miningDimensions then
                    commandMiningParams.x = commandResponse.miningDimensions.x
                    commandMiningParams.y = commandResponse.miningDimensions.y
                    commandMiningParams.z = commandResponse.miningDimensions.z

                    logger("Mining Dimensions:" .. commandMiningParams.x .. commandMiningParams.y ..
                               commandMiningParams.z)
                else
                    commandMiningParams = {}
                end
            else
                logger("no new commands")
            end

        else
            logger("no new commands")
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
