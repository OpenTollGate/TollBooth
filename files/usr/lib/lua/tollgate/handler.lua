
local cjson = require "cjson"
local api = require "tollbooth.api"

local request_method = os.getenv("REQUEST_METHOD")
local input_data = ""

if request_method == "POST" then
    input_data = io.read("*all")
elseif request_method == "GET" then
    --return status
end

local data = {}
if input_data ~= "" then
    data = cjson.decode(input_data)
end

local response = api.process_request(data)

print("Content-Type: application/json\r\n\r\n")
print(cjson.encode(response))
