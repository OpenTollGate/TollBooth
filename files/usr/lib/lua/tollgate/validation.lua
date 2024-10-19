-- validation.lua

local validation = {}
local cjson = require "cjson"

-- Configuration parameters (customizable)
-- validation.SESSION_TIMEOUT = 3600  -- Session timeout in seconds

-- Session storage (in-memory)
local sessions = {}

-- User validation logic
function validation.validate_user(data)

    -- Implement your custom validation logic here
    if data.username == "allowed_user" and data.password == "correct_password" then
        return true, "Access granted"
    else
        return false, "Invalid credentials"
    end
end

-- Add a session
function validation.add_session(mac_address)
    sessions[mac_address] = os.time()
end

-- Remove a session
function validation.remove_session(mac_address)
    sessions[mac_address] = nil
end

-- Check if a session exists
function validation.session_exists(mac_address)
    return sessions[mac_address] ~= nil
end

-- Cleanup expired sessions
function validation.cleanup_sessions()
    local current_time = os.time()
    for mac_address, timestamp in pairs(sessions) do
        if current_time - timestamp > validation.SESSION_TIMEOUT then
            -- Session expired
            auth.remove_session(mac_address)
            -- Deauthorize MAC address
            auth.deauthorize_mac(mac_address)
            print("Session expired for MAC:", mac_address)
        end
    end
end

-- Function to get all active sessions (optional, for monitoring)
function validation.get_sessions()
    return sessions
end

return validation
