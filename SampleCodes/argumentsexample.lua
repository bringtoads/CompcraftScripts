-- mine.lua
-- Read the input arguments
local args = {...}

if #args ~= 3 then
    print("Usage: mine <length> <width> <height>")
    return
end

-- Convert arguments to numbers
local length = tonumber(args[1])
local width = tonumber(args[2])
local height = tonumber(args[3])

-- Validate inputs
if not length or not width or not height then
    print("Invalid input! Please provide three numeric values.")
    return
end

print("Starting mining operation with dimensions:")
print("Length: " .. length .. " Width: " .. width .. " Height: " .. height)

-- You can now use these variables (length, width, height) to define your mining logic.
-- For example, you could loop to mine a 3D area of the given size.
