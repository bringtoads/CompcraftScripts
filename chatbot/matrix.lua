-- Matrix Digital Rain for ComputerCraft Monitor (8x4)
local monitor = peripheral.wrap("right") -- Adjust based on monitor position
local w, h = 8, 4
local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
local columns = {}

-- Initialize columns
for i = 1, w do
    columns[i] = {
        chars = {},
        speed = math.random(10, 20) / 10, -- Fractional speeds for smoother animation
        nextUpdate = 0
    }
    for j = 1, h do
        columns[i].chars[j] = {
            char = " ",
            brightness = 0
        }
    end
end

-- Set up monitor
monitor.clear()

-- Main animation loop
local t = 0
while true do
    for x = 1, w do
        local col = columns[x]
        if t >= col.nextUpdate then
            -- Shift characters down
            for y = h, 2, -1 do
                col.chars[y].char = col.chars[y-1].char
                col.chars[y].brightness = math.max(0, col.chars[y-1].brightness - 1)
            end
            -- New character at top
            if math.random() < 0.5 then
                col.chars[1].char = chars:sub(math.random(1, #chars), math.random(1, #chars))
                col.chars[1].brightness = 3 -- Max brightness
            else
                col.chars[1].char = " "
                col.chars[1].brightness = 0
            end
            col.nextUpdate = t + col.speed
        end
        
        -- Render column
        for y = 1, h do
            monitor.setCursorPos(x, y)
            if col.chars[y].brightness > 0 then
                if col.chars[y].brightness == 3 then
                    monitor.setTextColor(colors.white)
                elseif col.chars[y].brightness == 2 then
                    monitor.setTextColor(colors.lime)
                else
                    monitor.setTextColor(colors.green)
                end
                monitor.write(col.chars[y].char)
            else
                monitor.setTextColor(colors.black)
                monitor.write(" ")
            end
        end
    end
    
    sleep(0.05) -- Smoother animation
    t = t + 0.05
end