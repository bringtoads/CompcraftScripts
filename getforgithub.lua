function downloadScript(url, filename)
    local response = http.get(url)

    if response then
        local file = fs.open(filename, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        print("File downloaded successfully: " .. filename)
    else
        print("Failed to load from URL: " .. url)
    end
end

if #arg < 1 then
    print("Usage: scriptname <URL> [<filename>]")
    return
end

local url = arg[1]
local filename = arg[2] or "startup"

downloadScript(url, filename)
