-- Enhanced Pocket Computer UI with scrolling and additional features
-- Colors
local colors = {
    background = colors.black,
    header = colors.blue,
    text = colors.white,
    highlight = colors.yellow,
    button = colors.gray,
    buttonText = colors.white,
    selected = colors.lime,
    scrollbar = colors.lightGray,
    scrollbarHandle = colors.gray,
    alert = colors.red,
    success = colors.green
}

-- UI State
local state = {
    currentPage = "main",
    selectedButton = 1,
    menuScroll = 0,
    contentScroll = 0,
    notifications = {},
    menuItems = {{
        name = "Status",
        icon = "S",
        items = {"CPU Usage: 12%", "Memory: 45KB", "Uptime: 2h 15m", "Temperature: 25°C", "Battery: 85%",
                 "Disk Space: 2MB"}
    }, {
        name = "Files",
        icon = "F",
        items = {"Documents: 5 files", "Programs: 3 files", "Images: 2 files", "Storage: 80% used", "Recent Files:",
                 "  - notes.txt", "  - program.lua", "  - data.csv"}
    }, {
        name = "Network",
        icon = "N",
        items = {"WiFi: Connected", "Signal: Strong", "IP: 192.168.1.100", "Connected Devices: 3", "Bandwidth: 2MB/s",
                 "Ping: 5ms"}
    }, {
        name = "Apps",
        icon = "A",
        items = {"Calculator", "Notepad", "Terminal", "File Browser", "System Monitor", "Network Scanner"}
    }, {
        name = "Messages",
        icon = "M",
        items = {"New message from User1", "System update available", "Backup completed", "Low storage warning",
                 "Network status update"}
    }, {
        name = "Tools",
        icon = "T",
        items = {"Disk Cleanup", "System Scan", "Backup Tool", "Password Manager", "File Encryption"}
    }, {
        name = "Settings",
        icon = "C",
        items = {"Theme: Dark", "Volume: 80%", "Brightness: 75%", "Auto-Lock: 5min", "Notifications: On",
                 "Updates: Auto"}
    }},
    alerts = {},
    currentTime = "00:00",
    batteryLevel = 100
}

-- Get terminal size
local w, h = term.getSize()

-- Utility functions
local function createScrollBar(x, y, height, totalItems, visibleItems, currentScroll)
    local handleHeight = math.max(1, math.floor(height * (visibleItems / totalItems)))
    local scrollRange = height - handleHeight
    local handlePos = math.floor(scrollRange * (currentScroll / (totalItems - visibleItems)))

    -- Draw scrollbar background
    term.setBackgroundColor(colors.scrollbar)
    for i = 0, height - 1 do
        term.setCursorPos(x, y + i)
        term.write(" ")
    end

    -- Draw handle
    term.setBackgroundColor(colors.scrollbarHandle)
    for i = 0, handleHeight - 1 do
        term.setCursorPos(x, y + handlePos + i)
        term.write(" ")
    end
end

local function addNotification(message, type)
    table.insert(state.notifications, {
        message = message,
        type = type or "info",
        time = os.epoch("local")
    })
    if #state.notifications > 5 then
        table.remove(state.notifications, 1)
    end
end

-- Draw functions
local function drawHeader()
    term.setBackgroundColor(colors.header)
    term.setTextColor(colors.text)
    term.clear()

    -- Draw title
    term.setCursorPos(2, 1)
    term.write("Pocket Computer v2.0")

    -- Draw time
    term.setCursorPos(w - 13, 1)
    state.currentTime = textutils.formatTime(os.time(), true)
    term.write(state.currentTime)

    -- Draw battery
    term.setCursorPos(w - 5, 1)
    local batteryChar = state.batteryLevel > 80 and "≡" or state.batteryLevel > 60 and "≢" or state.batteryLevel >
                            40 and "≣" or state.batteryLevel > 20 and "≤" or "≥"
    term.write(batteryChar)
end

local function drawButton(x, y, text, icon, selected)
    if y < 3 or y > h - 1 then
        return
    end

    local width = 12
    local height = 3

    -- Draw button background with gradient effect
    term.setBackgroundColor(selected and colors.selected or colors.button)
    for i = 0, height - 1 do
        term.setCursorPos(x, y + i)
        term.write(string.rep(" ", width))
    end

    -- Draw icon and text with shadow effect
    if selected then
        term.setTextColor(colors.buttonText)
        term.setCursorPos(x + 1, y + 1)
        term.write(icon)
        term.setCursorPos(x + 1, y + 2)
        term.write(text)
    else
        term.setTextColor(colors.buttonText)
        term.setCursorPos(x + 1, y + 1)
        term.write(icon)
        term.setCursorPos(x + 1, y + 2)
        term.write(text)
    end
end

local function drawMenu()
    local buttonSpacing = 4
    local startX = 2
    local startY = 3 - state.menuScroll * buttonSpacing

    -- Draw menu buttons
    for i, item in ipairs(state.menuItems) do
        local x = startX
        local y = startY + (i - 1) * buttonSpacing
        drawButton(x, y, item.name, item.icon, i == state.selectedButton)
    end

    -- Draw scrollbar if needed
    if #state.menuItems * buttonSpacing > (h - 3) then
        createScrollBar(14, 3, h - 4, #state.menuItems * buttonSpacing, h - 3, state.menuScroll * buttonSpacing)
    end
end

local function drawContent()
    term.setBackgroundColor(colors.background)
    term.setTextColor(colors.text)

    local contentX = 16
    local contentY = 3
    local contentWidth = w - contentX - 2
    local contentHeight = h - contentY - 1

    -- Clear content area
    for y = contentY, h - 1 do
        term.setCursorPos(contentX, y)
        term.write(string.rep(" ", contentWidth))
    end

    -- Draw content based on selected page
    local currentItem = state.menuItems[state.selectedButton]

    -- Draw content header
    term.setBackgroundColor(colors.header)
    term.setCursorPos(contentX, contentY)
    term.write(string.rep(" ", contentWidth))
    term.setCursorPos(contentX + 2, contentY)
    term.write(currentItem.name)

    -- Draw content items with scroll
    term.setBackgroundColor(colors.background)
    local items = currentItem.items
    for i, item in ipairs(items) do
        local y = contentY + 2 + (i - 1) - state.contentScroll
        if y >= contentY + 2 and y < h - 1 then
            term.setCursorPos(contentX + 2, y)
            term.write(item)
        end
    end

    -- Draw content scrollbar if needed
    if #items > (contentHeight - 2) then
        createScrollBar(w - 1, contentY + 2, contentHeight - 2, #items, contentHeight - 2, state.contentScroll)
    end

    -- Draw notifications
    local notificationY = h - #state.notifications - 1
    for i, notification in ipairs(state.notifications) do
        term.setCursorPos(contentX + 2, notificationY + i)
        term.setTextColor(notification.type == "error" and colors.alert or colors.success)
        term.write(notification.message)
    end
end

-- Handle input
local function handleTouch(x, y)
    local buttonSpacing = 4
    local startX = 2
    local startY = 3

    -- Check if touch is within button areas
    for i = 1, #state.menuItems do
        local buttonY = startY + (i - 1) * buttonSpacing - state.menuScroll * buttonSpacing
        if y >= buttonY and y < buttonY + 3 and x >= startX and x < startX + 12 then
            if state.selectedButton ~= i then
                state.selectedButton = i
                state.contentScroll = 0 -- Reset content scroll on page change
                addNotification("Switched to " .. state.menuItems[i].name, "info")
            end
            return true
        end
    end

    -- Check if touch is on scrollbar
    if x == 14 and y >= 3 and y < h - 1 then
        local totalHeight = #state.menuItems * buttonSpacing
        local visibleHeight = h - 3
        state.menuScroll = math.floor((y - 3) * (totalHeight - visibleHeight) / (h - 4))
        state.menuScroll = math.max(0, math.min(state.menuScroll, totalHeight - visibleHeight))
        return true
    end

    return false
end

-- Periodic updates
local function updateSystem()
    -- Update battery level (simulated)
    state.batteryLevel = state.batteryLevel - 1
    if state.batteryLevel < 0 then
        state.batteryLevel = 100
    end

    -- Add random alerts occasionally
    if math.random() < 0.1 then
        local alerts = {"New message received", "Battery level low", "Network connection changed",
                        "System update available", "Storage space running low"}
        addNotification(alerts[math.random(1, #alerts)], math.random() > 0.5 and "error" or "info")
    end
end

-- Main loop
local function main()
    local lastUpdate = os.epoch("local")

    while true do
        -- Draw UI
        drawHeader()
        drawMenu()
        drawContent()

        -- Handle events
        local timer = os.startTimer(0.5) -- For periodic updates

        local event, p1, x, y = os.pullEvent()
        if event == "mouse_click" then
            if handleTouch(x, y) then
                -- Add subtle animation
                term.setBackgroundColor(colors.highlight)
                sleep(0.1)
            end
        elseif event == "mouse_scroll" then
            -- Handle scrolling
            if x < 15 then
                -- Menu scroll
                state.menuScroll = math.max(0, math.min(state.menuScroll + p1,
                    math.max(0, (#state.menuItems * 4 - (h - 3)) / 4)))
            else
                -- Content scroll
                local currentItems = state.menuItems[state.selectedButton].items
                state.contentScroll = math.max(0,
                    math.min(state.contentScroll + p1, math.max(0, #currentItems - (h - 6))))
            end
        elseif event == "key" then
            if p1 == keys.up then
                if state.selectedButton > 1 then
                    state.selectedButton = state.selectedButton - 1
                    state.contentScroll = 0
                end
            elseif p1 == keys.down then
                if state.selectedButton < #state.menuItems then
                    state.selectedButton = state.selectedButton + 1
                    state.contentScroll = 0
                end
            end
        elseif event == "timer" and p1 == timer then
            -- Periodic updates
            local currentTime = os.epoch("local")
            if currentTime - lastUpdate > 1000 then -- Update every second
                updateSystem()
                lastUpdate = currentTime
            end
        end
    end
end

-- Start the UI
term.clear()
addNotification("System started successfully", "success")
main()
