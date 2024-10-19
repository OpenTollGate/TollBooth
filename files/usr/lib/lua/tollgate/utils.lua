function execute_command(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    local success, _, exit_code = handle:close()
    return result, exit_code
end