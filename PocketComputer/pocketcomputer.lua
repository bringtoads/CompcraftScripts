-- Function to draw a button
local function drawButton(x, y, label)
    -- Set button color
    paintutils.drawFilledBox(x, y, x + string.len(label) + 1, y + 1, colors.lightGray)
    term.setCursorPos(x + 1, y + 1) -- Move cursor for label
    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.black) -- Set text color
    term.write(label)
    term.setBackgroundColor(colors.black) -- Reset background color
    term.setTextColor(colors.white) -- Reset text color
end

-- Function to send commands to the server
local function sendCommand(turtleId, command)
    -- Modify the URL to include the turtle ID
    local url = "http://your.api.endpoint/turtles/" .. turtleId .. "/command" -- Example endpoint: http://your.api.endpoint/turtles/Turtle1/command
    local body = textutils.serializeJSON({
        command = command
    })

    local response, err = http.post(url, body, {
        ["Content-Type"] = "application/json"
    })
    if not response then
        print("Error sending command: " .. err)
        return
    end

    local responseBody = response.readAll()
    print("Response from server: " .. responseBody)
    response.close()
end

-- Main UI Loop
local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("Pocket Computer - Turtle Controller")

    -- Example list of turtles - replace with your actual registered turtle IDs
    local turtles = {"Turtle1", "Turtle2", "Turtle3"}
    local yPos = 3

    for _, turtle in ipairs(turtles) do
        drawButton(1, yPos, "Control " .. turtle)
        yPos = yPos + 3
    end

    -- Draw command buttons
    drawButton(1, yPos + 1, "Go Mine")
    drawButton(1, yPos + 3, "Return Home")

    local selectedTurtle

    while true do
        local event, button, x, y = os.pullEvent("mouse_click")

        -- Check if a turtle button was clicked
        if y >= 3 and y < yPos then
            local turtleIndex = math.floor((y - 3) / 3) + 1
            if turtles[turtleIndex] then
                selectedTurtle = turtles[turtleIndex]
                print("Selected: " .. selectedTurtle)
            end
        elseif y == yPos + 1 and x >= 1 and x <= 9 then
            -- 'Go Mine' button
            if selectedTurtle then
                sendCommand(selectedTurtle, "goMine")
            else
                print("Please select a turtle first.")
            end
        elseif y == yPos + 3 and x >= 1 and x <= 12 then
            -- 'Return Home' button
            if selectedTurtle then
                sendCommand(selectedTurtle, "returnHome")
            else
                print("Please select a turtle first.")
            end
        end
    end
end

main()
