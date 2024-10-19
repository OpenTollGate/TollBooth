
local socket = require "socket.unix"
local validation = require "tollbooth.validation"
local auth = require "tollbooth.auth"

local SOCKET_PATH = "/tmp/tollbooth_daemon.sock"
local CHECK_INTERVAL = 60

local function handle_signal(signum)
    print("Daemon received signal:", signum)
    os.exit(0)
end

local function setup_signal_handlers()
    local signal = require "posix.signal"
    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
end

local function handle_command(command)
    local cmd = command.cmd
    local mac_address = command.mac_address
    local response = {}

    if cmd == "ADD_SESSION" then
        validation.add_session(mac_address)
        auth.authorize_mac(mac_address)
        response.status = "OK"
    elseif cmd == "REMOVE_SESSION" then
        validation.remove_session(mac_address)
        auth.deauthorize_mac(mac_address)
        response.status = "OK"
    elseif cmd == "SESSION_EXISTS" then
        if validation.session_exists(mac_address) then
            response.status = "EXISTS"
        else
            response.status = "NOT_FOUND"
        end
    else
        response.status = "ERROR"
        response.message = "Unknown command"
    end

    return response
end

local function main()

    setup_signal_handlers()

    os.remove(SOCKET_PATH)

    local server = assert(socket(), "Failed to create socket")
    assert(server:bind(SOCKET_PATH), "Failed to bind socket")
    assert(server:listen(), "Failed to listen on socket")

    os.execute("chmod 777 " .. SOCKET_PATH)

    print("Tollbooth daemon started.")

    local last_cleanup = os.time()

    while true do
        server:settimeout(1)
        local client = server:accept()

        if client then
            local data, err = client:receive()
            if data then
                local command = cjson.decode(data)
                local response = handle_command(command)
                client:send(cjson.encode(response) .. "\n")
            end
            client:close()
        end

        if os.time() - last_cleanup >= CHECK_INTERVAL then
            validation.cleanup_sessions()
            last_cleanup = os.time()
        end
    end
end

main()
