local utils = require "tollbooth.utils"

function authorize_mac(mac_address)
    local cmd = string.format("iptables -I tollbooth -m mac --mac-source %s -j RETURN", mac_address)
    utils.execute_command(cmd)
end

function deauthorize_mac(mac_address)
    local cmd = string.format("iptables -D tollbooth -m mac --mac-source %s -j RETURN", mac_address)
    utils.execute_command(cmd)
end
