-- request
local http = require("http")

local url = "http://example.com/api"
local postData = '{"key":"value"}' -- JSON format for POST data
local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer your_token_here"
}

local function makeRequest()
    local response = http.request(url, postData, headers)

    if response then
        print("Request successful. Response: " .. response)
    else
        print("Request failed.")
    end
end

makeRequest()

-- get
local http = require("http")

local url = "http://example.com/api"
local headers = {
    ["Accept"] = "application/json",
    ["User-Agent"] = "LuaHttpClient/1.0"
}

local function getRequest()
    local response = http.get(url, headers)

    if response then
        print("GET request successful. Response: " .. response)
    else
        print("GET request failed.")
    end
end

getRequest()

-- post
local http = require("http")

local url = "http://example.com/api"
local postData = '{"key":"value"}' -- JSON format for POST data
local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer your_token_here"
}

local function postRequest()
    local response = http.post(url, postData, headers)

    if response then
        print("POST request successful. Response: " .. response)
    else
        print("POST request failed.")
    end
end

postRequest()

-- check url
local http = require("http")

local url = "http://example.com/api"

local function checkUrl()
    local success, error = http.checkURL(url)

    if success then
        print("URL is valid and whitelisted.")
    else
        print("URL check failed: " .. (error or "Unknown error"))
    end
end

checkUrl()
