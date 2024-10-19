local socket = require "socket.unix"
local cjson = require "cjson.safe"

local api = {}

local SOCKET_PATH = "/tmp/tollbooth_daemon.sock"

function api.process_request(data)
    local is_valid, result = api.validate_user(data)

    if is_valid then
        local mac_address = api.get_client_mac_address()

        if mac_address then
            local command = { cmd = "ADD_SESSION", mac_address = mac_address }
            local response, err = api.send_command(command)

            if response and response.status == "OK" then
                return { status = "accepted", message = result }
            else
                return { status = "error", error = "Failed to add session: " .. (err or "Unknown error") }
            end
        else
            return { status = "error", error = "Unable to retrieve MAC address" }
        end
    else
        return { status = "denied", error = result }
    end
end

function api.validate_user(data)
    local validation = require "tollbooth.validation"
    return validation.validate_user(data)
end

function api.get_client_mac_address()
    local client_ip = os.getenv("REMOTE_ADDR")

    if not client_ip then
        return nil
    end

    local cmd = string.format("arp -n %s | awk '/%s/ {print $3}'", client_ip, client_ip)
    local mac_address = io.popen(cmd):read("*a")
    mac_address = mac_address and mac_address:match("%S+")

    return mac_address
end

function api.send_command(command)
    local client = socket()
    if not client then
        return nil, "Failed to create socket"
    end

    local connected, err = client:connect(SOCKET_PATH)
    if not connected then
        client:close()
        return nil, "Failed to connect to daemon: " .. err
    end

    client:send(cjson.encode(command) .. "\n")
    local response = client:receive()
    client:close()

    if response then
        return cjson.decode(response)
    else
        return nil, "No response from daemon"
    end
end

return api
