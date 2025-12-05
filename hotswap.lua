-- Simple hot reload for LÖVE2D
-- No external dependencies

local hotswap = {}

local watch = {}
local last_modified = {}

function hotswap.update()
    for _, path in ipairs(watch) do
        local info = love.filesystem.getInfo(path)
        if info then
            local mod_time = info.modtime
            if last_modified[path] and last_modified[path] ~= mod_time then
                print("[hotswap] Reloading: " .. path)

                -- Clear from package cache
                package.loaded[path:gsub("%.lua$", "")] = nil

                -- Reload the module
                local success, err = pcall(function()
                    require(path:gsub("%.lua$", ""))
                end)

                if not success then
                    print("[hotswap] Error reloading: " .. err)
                end
            end
            last_modified[path] = mod_time
        end
    end
end

function hotswap.watch(path)
    table.insert(watch, path)
    local info = love.filesystem.getInfo(path)
    if info then
        last_modified[path] = info.modtime
    end
end

return hotswap
