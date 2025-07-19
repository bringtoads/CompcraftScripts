-- TurtleController.lua

local TurtleController = {}
TurtleController.__index = TurtleController

function TurtleController:new(turtleId, turtlesUrl)
    local self = setmetatable({}, TurtleController)
    self.DIRECTIONS = { SOUTH = 0, WEST = 1, NORTH = 2, EAST = 3 }
    self.STATUS = { IDLE = "idle", MINING = "mining", STOPPED = "stopped", RUNNING = "running" }
    self.HOME_COORDINATES = { x = 0, y = 0, z = 0 }

    self.turtleId = turtleId or os.getComputerID()
    self.turtlesUrl = turtlesUrl or "http://localhost:5041/api/turtles/"
    self.position = { x = 0, y = 0, z = 0 }
    self.direction = self.DIRECTIONS.SOUTH
    self.status = self.STATUS.IDLE
    self.fuelLevel = turtle.getFuelLevel()
    self.inventory = {}
    self.currentCommand = nil
    self.commandMiningParams = { x = 0, y = 0, z = 0 }
    return self
end

function TurtleController:logger(msg)
    print(msg)
end

function TurtleController:getCurrentCoordinates()
    if gps and gps.locate then
        local x, y, z = gps.locate()
        if x and y and z then
            self.position = { x = x, y = y, z = z }
            return true
        else
            print("GPS coordinates not found.")
            return false
        end
    else
        print("GPS not available.")
        return false
    end
end

function TurtleController:getFacingDirection()
    if self:getCurrentCoordinates() then
        turtle.forward()
        local x, y, z = gps.locate()
        turtle.back()
        if x < self.position.x then
            self.direction = self.DIRECTIONS.EAST
        elseif x > self.position.x then
            self.direction = self.DIRECTIONS.WEST
        elseif z > self.position.z then
            self.direction = self.DIRECTIONS.SOUTH
        elseif z < self.position.z then
            self.direction = self.DIRECTIONS.NORTH
        end
    end
end

function TurtleController:updatePosition()
    if self.direction == self.DIRECTIONS.SOUTH then
        self.position.z = self.position.z + 1
    elseif self.direction == self.DIRECTIONS.WEST then
        self.position.x = self.position.x - 1
    elseif self.direction == self.DIRECTIONS.NORTH then
        self.position.z = self.position.z - 1
    elseif self.direction == self.DIRECTIONS.EAST then
        self.position.x = self.position.x + 1
    end
end

function TurtleController:getInventory()
    self.inventory = {}
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            table.insert(self.inventory, { BlockName = item.name, BlockCount = item.count, Slot = slot })
        end
    end
end

function TurtleController:register()
    self:getCurrentCoordinates()
    self:getInventory()
    local data = {
        InGameId = self.turtleId,
        CurrentPosition = self.position,
        FuelLevel = self.fuelLevel,
        Inventory = self.inventory,
        Status = self.status
    }
    local jsonData = textutils.serializeJSON(data)
    local url = self.turtlesUrl .. "register"
    local headers = { ["Content-Type"] = "application/json" }
    local response = http.post(url, jsonData, headers)
    if response then
        local responseData = response.readAll()
        response.close()
        local result = textutils.unserializeJSON(responseData)
        if result and result.success then
            os.setComputerLabel(result.data.name)
            print("Registered as " .. result.data.name)
        else
            print("Registration failed.")
        end
    else
        print("HTTP request failed.")
    end
end

function TurtleController:getNextCommand()
    local response = http.get(self.turtlesUrl .. self.turtleId .. "/next-command")
    if response then
        local data = response.readAll()
        response.close()
        local result = textutils.unserializeJSON(data)
        if result and result.success then
            self.currentCommand = result.data.command
            if result.data.miningDimensions then
                self.commandMiningParams = result.data.miningDimensions
            end
        else
            self.currentCommand = nil
        end
    else
        self.currentCommand = nil
    end
end

function TurtleController:pollCommands()
    while true do
        self:getNextCommand()
        sleep(3)
    end
end

function TurtleController:executeCommands()
    while true do
        local cmd = self.currentCommand
        if cmd == "forward" then
            turtle.forward()
            self:updatePosition()
        elseif cmd == "backward" then
            turtle.back()
            self:updatePosition()
        elseif cmd == "right" then
            turtle.turnRight()
            self.direction = (self.direction + 1) % 4
        elseif cmd == "left" then
            turtle.turnLeft()
            self.direction = (self.direction - 1) % 4
        elseif cmd == "up" then
            turtle.up()
            self.position.y = self.position.y + 1
        elseif cmd == "down" then
            turtle.down()
            self.position.y = self.position.y - 1
        elseif cmd == "mine" then
            -- implement your mine logic here
        elseif cmd == "returnHome" then
            -- implement your return home logic here
        end
        self.currentCommand = nil
        sleep(1)
    end
end

function TurtleController:init()
    print("Initializing Turtle Bot...")
    self:getFacingDirection()
    self:register()
    parallel.waitForAll(
        function() self:pollCommands() end,
        function() self:executeCommands() end
    )
end

return TurtleController