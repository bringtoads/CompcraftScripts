local url = "https://raw.githubusercontent.com/username/repository-name/main/your-script.lua" -- Replace with your script's URL
local filename = "Initialize" --

function downlaodScript(url, filenam)
    local response = http.get(url)

    if response then
        local file = fs.open(filename, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        print("file downloaded successfully:" .. filenam)

    else
        print("failed to load:" .. filenam)
    end
end

-- Function to run a specified Lua script with parameters
function runScript(filename, ...)
    if fs.exists(filename) then
        local args = {...} -- Capture any additional arguments
        local command = "shell.run('" .. filename .. "'"

        -- Append parameters to the command if provided
        for _, arg in ipairs(args) do
            command = command .. ", '" .. arg .. "'"
        end
        command = command .. ")"

        -- Execute the command
        load(command)()
    else
        print("File does not exist: " .. filename)
    end
end

-- Example usage

-- Download the script
downloadScript(url, filename)

-- Run the script with parameters
runScript(filename, "param1", "param2") -- Replace with actual parameters if needed
