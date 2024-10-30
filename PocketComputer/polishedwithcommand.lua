-- Turtle Controller UI
-- Uses built-in JSON parsing
-- Configuration
local API_BASE_URL = "http://localhost:5041/api/turtles"
local WINDOW_WIDTH, WINDOW_HEIGHT = term.getSize()
local HEADER_HEIGHT = 3
local FOOTER_HEIGHT = 3
local MAX_TURTLE_NAME_LENGTH = 20

-- Color scheme
local COLORS = {
    background = colors.black,
    header = colors.blue,
    selected = colors.gray,
    text = colors.white,
    highlight = colors.yellow,
    error = colors.red,
    success = colors.lime
}

-- UI State
local state = {
    turtles = {},
    selectedTurtle = nil,
    scroll = 0,
    maxScroll = 0,
    commandHistory = {},
    status = ""
}
-- logging cause i am dumb and will eventually run into problems
local function logger(data)
    print(data)
end
-- Function to print data for a single turtle
local function printTurtleData(turtle)
    print("Turtle ID:", turtle.id)
    print("In-Game ID:", turtle.inGameId)
    print("Name:", turtle.name)
    print("Is Active:", turtle.isActive)
    print("Fuel Level:", turtle.fuelLevel)
    print("Coordinates: X:", turtle.currentCoordinates.x, "Y:", turtle.currentCoordinates.y, "Z:",
        turtle.currentCoordinates.z)

    -- Loop through the inventory
    for _, item in ipairs(turtle.inventory) do
        print("Inventory Slot:", item.slot)
        print("Block Name:", item.blockName)
        print("Block Count:", item.blockCount)
    end
end

-- Helper functions
local function centerText(text, y, color)
    local x = math.floor((WINDOW_WIDTH - #text) / 2)
    term.setCursorPos(x, y)
    if color then
        term.setTextColor(color)
    end
    write(text)
end

local function drawBox(x, y, width, height, color)
    local oldBg = term.getBackgroundColor()
    term.setBackgroundColor(color or COLORS.background)
    for i = y, y + height - 1 do
        term.setCursorPos(x, i)
        write(string.rep(" ", width))
    end
    term.setBackgroundColor(oldBg)
end

-- API interaction functions
local function fetchTurtles()
    local response = http.get(API_BASE_URL .. "/getTurtles")

    if response then
        local responseData = response.readAll()
        response.close()
        logger(responseData) -- working
        local datatable = textutils.unserializeJSON(responseData)

        if datatable.success then
            -- Loop through each turtle and call printTurtleData
            for _, turtle in ipairs(datatable.data) do
                printTurtleData(turtle)
            end
        else
            print("API response was unsuccessful. Message:", data.message)
        end
        state.turtles = datatable.data
        state.maxScroll = math.max(0, #state.turtles - (WINDOW_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT))
    else
        state.status = "Failed to fetch turtles"
    end
end

local function sendCommand(turtleId, command)
    local payload = {
        Command = command,
        MiningDimensions = nil -- Add mining dimensions if needed
    }

    local response = http.post(API_BASE_URL .. "/" .. turtleId .. "/command", textutils.jsonStringify(payload), {
        ["Content-Type"] = "application/json"
    })

    if response then
        local data = textutils.jsonParse(response.readAll())
        response.close()
        if data.Success then
            state.status = "Command sent successfully"
            return true
        else
            state.status = "Command failed: " .. (data.Message or "Unknown error")
            return false
        end
    else
        state.status = "Failed to send command"
        return false
    end
end

-- UI Components
local function drawHeader()
    drawBox(1, 1, WINDOW_WIDTH, HEADER_HEIGHT, COLORS.header)
    centerText("Turtle Control Center", 2, COLORS.text)
end

local function drawFooter()
    local y = WINDOW_HEIGHT - FOOTER_HEIGHT + 1
    drawBox(1, y, WINDOW_WIDTH, FOOTER_HEIGHT, COLORS.header)
    centerText(state.status, y + 1, COLORS.text)
    centerText("Press Q to quit", y + 2, COLORS.text)
end

local function drawTurtleList()
    local listArea = WINDOW_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT
    local startY = HEADER_HEIGHT + 1

    for i = 1, listArea do
        local turtleIndex = i + state.scroll
        local turtle = state.turtles[turtleIndex]
        local y = startY + i - 1

        -- Clear line
        term.setCursorPos(1, y)
        term.setBackgroundColor(COLORS.background)
        write(string.rep(" ", WINDOW_WIDTH))

        if turtle then
            -- Highlight selected turtle
            if state.selectedTurtle == turtleIndex then
                term.setBackgroundColor(COLORS.selected)
                term.setCursorPos(1, y)
                write(string.rep(" ", WINDOW_WIDTH))
            end

            -- Draw turtle info
            term.setCursorPos(2, y)
            term.setTextColor(COLORS.text)
            local name = "Turtle #" .. turtle.inGameId
            if turtle.name then
                name = name .. " (" .. turtle.name .. ")"
            end
            write(name:sub(1, MAX_TURTLE_NAME_LENGTH))
        end
    end
end

local function handleCommand()
    if not state.selectedTurtle then
        state.status = "No turtle selected"
        return
    end

    local turtle = state.turtles[state.selectedTurtle]
    term.setCursorPos(1, WINDOW_HEIGHT - 1)
    term.clearLine()
    term.setTextColor(COLORS.highlight)
    write("Command for Turtle #" .. turtle.inGameId .. ": ")

    local command = read()
    if command and #command > 0 then
        if sendCommand(turtle.inGameId, command) then
            table.insert(state.commandHistory, {
                turtleId = turtle.inGameId,
                command = command
            })
        end
    end
end

-- Main UI loop
local function mainLoop()
    term.clear()
    term.setCursorPos(1, 1)

    -- Initial fetch
    fetchTurtles()

    while true do
        -- Draw UI
        drawHeader()
        drawTurtleList()
        drawFooter()

        -- Handle input
        local event, key = os.pullEvent("key")

        if key == keys.q then
            break
        elseif key == keys.up and state.selectedTurtle > 1 then
            state.selectedTurtle = state.selectedTurtle - 1
            if state.selectedTurtle <= state.scroll then
                state.scroll = state.scroll - 1
            end
        elseif key == keys.down and state.selectedTurtle < #state.turtles then
            state.selectedTurtle = state.selectedTurtle + 1
            if state.selectedTurtle - state.scroll > WINDOW_HEIGHT - HEADER_HEIGHT - FOOTER_HEIGHT then
                state.scroll = state.scroll + 1
            end
        elseif key == keys.enter then
            handleCommand()
        elseif key == keys.r then
            fetchTurtles()
            state.status = "Turtle list refreshed"
        end

        -- Select first turtle if none selected
        if #state.turtles > 0 and not state.selectedTurtle then
            state.selectedTurtle = 1
        end
    end
end

-- Start the application
term.clear()
term.setCursorPos(1, 1)
mainLoop()
term.clear()
term.setCursorPos(1, 1)
