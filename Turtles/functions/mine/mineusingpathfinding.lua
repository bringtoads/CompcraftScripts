local function mineVolume(length, width, height)
    -- Function to check and refuel if needed
    local function checkFuel(blocksNeeded)
        local currentFuel = turtle.getFuelLevel()
        if currentFuel == "unlimited" then
            return true
        end
        -- Calculate fuel needed (blocks to mine + return journey)
        local fuelNeeded = blocksNeeded + 100 -- Adding buffer for return journey
        if currentFuel < fuelNeeded then
            for i = 1, 16 do
                turtle.select(i)
                if turtle.refuel(0) then
                    turtle.refuel(64)
                    if turtle.getFuelLevel() >= fuelNeeded then
                        return true
                    end
                end
            end
            return false
        end
        return true
    end
    -- Function to return to starting position
    local function returnToStart(length, width, height)
        -- Turn around
        turtle.turnRight()
        turtle.turnRight()
        -- Return to ground level
        for i = 1, height - 1 do
            turtle.down()
        end
        -- Return to start position
        for i = 1, length - 1 do
            turtle.forward()
        end
        -- Return to first row
        turtle.turnRight()
        for i = 1, width - 1 do
            turtle.forward()
        end
        -- Face original direction
        turtle.turnLeft()
    end
    logger("length:" .. length .. " width:" .. width .. " height:" .. height)
    -- Calculate total blocks for fuel check
    local totalBlocks = length * width * height
    -- Check if we have enough fuel
    if not checkFuel(totalBlocks * 2) then -- *2 for safety margin
        print("Not enough fuel! Need at least " .. totalBlocks * 2 .. " fuel.")
        return false
    end
    print("Starting mining operation: " .. length .. "x" .. width .. "x" .. height)
    -- For each level
    for h = 1, height do
        -- For each width row
        for w = 1, width do
            -- Mine forward for length
            for l = 1, length do
                turtle.dig()
                if l < length then
                    turtle.forward()
                end
            end
            -- If not at last width, prepare for next row
            if w < width then
                if w % 2 == 1 then
                    turtle.turnRight()
                    turtle.dig()
                    turtle.forward()
                    turtle.turnRight()
                else
                    turtle.turnLeft()
                    turtle.dig()
                    turtle.forward()
                    turtle.turnLeft()
                end
            end
        end
        -- If not at top level, move up and reset position
        if h < height then
            -- Return to start of level if at even width
            if width % 2 == 0 then
                returnToStart(length, width, 1)
            end
            -- Move up
            turtle.digUp()
            turtle.up()
            -- If at even width, need to turn around
            if width % 2 == 0 then
                turtle.turnRight()
                turtle.turnRight()
            end
        end
    end
    -- Return to starting position
    if width % 2 == 0 and height % 2 == 1 then
        -- If both width is even and height is odd, we're direction wrong way
        returnToStart(length, width, height)
    elseif width % 2 == 1 and height % 2 == 0 then
        -- If width is odd and height is even, we're direction wrong way
        returnToStart(length, width, height)
    end
    print("Mining operation completed!")
    return true
end

local position = {
    x = 0,
    y = 0,
    z = 0
} -- Relative to start
local direction = 0 -- 0=north, 1=east, 2=south, 3=west
local knownBlocks = {} -- Store known empty spaces and obstacles
-- Constants
local INVENTORY_SLOTS = 16
local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
local DIRECTIONS = {
    [NORTH] = {
        x = 0,
        z = -1
    },
    [EAST] = {
        x = 1,
        z = 0
    },
    [SOUTH] = {
        x = 0,
        z = 1
    },
    [WEST] = {
        x = -1,
        z = 0
    }
}
-- Helper function to get block key for knownBlocks table
local function getBlockKey(x, y, z)
    return x .. "," .. y .. "," .. z
end
-- Update known blocks map
local function updateKnownBlock(x, y, z, isBlocked)
    knownBlocks[getBlockKey(x, y, z)] = isBlocked
end
-- Check if position is known to be blocked
local function isBlocked(x, y, z)
    local key = getBlockKey(x, y, z)
    return knownBlocks[key] == true
end
-- Update current position after movement
local function updatePosition(success)
    if success then
        local dir = DIRECTIONS[direction]
        position.x = position.x + (dir.x or 0)
        position.z = position.z + (dir.z or 0)
    end
end
-- Basic movement functions with position tracking
local function forward()
    local success = turtle.forward()
    updatePosition(success)
    return success
end
local function up()
    local success = turtle.up()
    if success then
        position.y = position.y + 1
    end
    return success
end
local function down()
    local success = turtle.down()
    if success then
        position.y = position.y - 1
    end
    return success
end
local function turnLeft()
    turtle.turnLeft()
    direction = (direction - 1) % 4
end
local function turnRight()
    turtle.turnRight()
    direction = (direction + 1) % 4
end
-- A* pathfinding implementation
local function manhattan3D(x1, y1, z1, x2, y2, z2)
    return math.abs(x2 - x1) + math.abs(y2 - y1) + math.abs(z2 - z1)
end
local function getNeighbors(x, y, z)
    local neighbors = {}
    local offsets = {{
        x = 0,
        y = 1,
        z = 0
    }, -- up
    {
        x = 0,
        y = -1,
        z = 0
    }, -- down
    {
        x = 1,
        y = 0,
        z = 0
    }, -- east
    {
        x = -1,
        y = 0,
        z = 0
    }, -- west
    {
        x = 0,
        y = 0,
        z = 1
    }, -- south
    {
        x = 0,
        y = 0,
        z = -1
    } -- north
    }
    for _, offset in ipairs(offsets) do
        local newX = x + offset.x
        local newY = y + offset.y
        local newZ = z + offset.z
        -- Check if position is valid and not blocked
        if not isBlocked(newX, newY, newZ) then
            table.insert(neighbors, {
                x = newX,
                y = newY,
                z = newZ
            })
        end
    end
    return neighbors
end
local function findPath(startX, startY, startZ, targetX, targetY, targetZ)
    local openSet = {}
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}
    -- Initialize start node
    local startNode = getBlockKey(startX, startY, startZ)
    openSet[startNode] = true
    gScore[startNode] = 0
    fScore[startNode] = manhattan3D(startX, startY, startZ, targetX, targetY, targetZ)
    while next(openSet) do
        -- Find node with lowest fScore
        local current = nil
        local lowestF = math.huge
        for node in pairs(openSet) do
            if fScore[node] < lowestF then
                current = node
                lowestF = fScore[node]
            end
        end
        -- Check if we reached the target
        if current == getBlockKey(targetX, targetY, targetZ) then
            local path = {}
            while current do
                local x, y, z = current:match("(-?%d+),(-?%d+),(-?%d+)")
                table.insert(path, 1, {
                    x = tonumber(x),
                    y = tonumber(y),
                    z = tonumber(z)
                })
                current = cameFrom[current]
            end
            return path
        end
        -- Move current node from open to closed set
        openSet[current] = nil
        closedSet[current] = true
        -- Get x, y, z from current node key
        local x, y, z = current:match("(-?%d+),(-?%d+),(-?%d+)")
        x, y, z = tonumber(x), tonumber(y), tonumber(z)
        -- Check neighbors
        for _, neighbor in ipairs(getNeighbors(x, y, z)) do
            local neighborKey = getBlockKey(neighbor.x, neighbor.y, neighbor.z)
            if not closedSet[neighborKey] then
                local tentativeG = gScore[current] + 1
                if not openSet[neighborKey] then
                    openSet[neighborKey] = true
                elseif tentativeG >= gScore[neighborKey] then
                    goto continue
                end
                cameFrom[neighborKey] = current
                gScore[neighborKey] = tentativeG
                fScore[neighborKey] = gScore[neighborKey] +
                                          manhattan3D(neighbor.x, neighbor.y, neighbor.z, targetX, targetY, targetZ)
            end
            ::continue::
        end
    end
    return nil -- No path found
end
-- Inventory management
local function isInventoryFull()
    for slot = 1, INVENTORY_SLOTS do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end
-- Function to navigate to a specific position
local function navigateToPosition(targetX, targetY, targetZ)
    local path = findPath(position.x, position.y, position.z, targetX, targetY, targetZ)
    if not path then
        print("No path found!")
        return false
    end
    -- Follow the path
    for i = 2, #path do -- Start from 2 as 1 is current position
        local node = path[i]
        local dx = node.x - position.x
        local dy = node.y - position.y
        local dz = node.z - position.z
        -- Handle vertical movement first
        if dy > 0 then
            up()
        elseif dy < 0 then
            down()
        end
        -- Handle horizontal movement
        if dx ~= 0 or dz ~= 0 then
            -- Calculate target direction
            local targetFacing
            if dx > 0 then
                targetFacing = EAST
            elseif dx < 0 then
                targetFacing = WEST
            elseif dz > 0 then
                targetFacing = SOUTH
            else
                targetFacing = NORTH
            end
            -- Turn to face target direction
            while direction ~= targetFacing do
                turnRight()
            end
            -- Move forward
            forward()
        end
    end
    return true
end
-- Function to return to chest and deposit items
local function returnToChestAndDeposit()
    -- Navigate back to position above chest
    if not navigateToPosition(dropChestPos.x, dropChestPos.y, dropChestPos.z) then
        print("Failed to find path back to chest!")
        return false
    end
    -- Deposit items
    down() -- Move down to chest level
    for slot = 1, INVENTORY_SLOTS do
        turtle.select(slot)
        turtle.dropDown()
    end
    up() -- Move back up
    return true
end
-- Main mining function with inventory management
function smartMine(length, width, height)
    -- Initialize starting position
    -- dropChestPos.x = position.x
    -- dropChestPos.y = position.y
    -- dropChestPos.z = position.z
    -- local tempPos = {}
    -- Main mining loop
    for h = 1, height do
        for w = 1, width do
            for l = 1, length do
                -- Check inventory before mining
                if isInventoryFull() then
                    print("Inventory full, returning to chest...")
                    returnToChestAndDeposit()
                    print("Returning to mining position...")
                    navigateToPosition(position.x, position.y, position.z)
                end
                -- Mine and move
                turtle.dig()
                if l < length then
                    forward()
                    -- Update known blocks
                    updateKnownBlock(position.x, position.y, position.z, false)
                end
            end
            -- Handle width movement
            if w < width then
                if w % 2 == 1 then
                    turnRight()
                    turtle.dig()
                    forward()
                    turnRight()
                else
                    turnLeft()
                    turtle.dig()
                    forward()
                    turnLeft()
                end
                updateKnownBlock(position.x, position.y, position.z, false)
            end
        end
        -- Handle height movement
        if h < height then
            turtle.digUp()
            up()
            updateKnownBlock(position.x, position.y, position.z, false)
            -- Reset position for next layer
            if width % 2 == 0 then
                turnRight()
                turnRight()
            end
        end
    end
    -- Return to chest after mining is complete
    print("Mining complete, returning to chest...")
    returnToChestAndDeposit()
    print("Operation completed successfully!")
end

