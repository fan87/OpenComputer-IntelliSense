local package = require("package")
local internet = require("internet")

-- Source of Code Completion
-- https://github.com/MightyPirates/OpenComputers/blob/master-MC1.12/src/main/resources/assets/opencomputers/loot/openos/lib/core/lua_shell.lua

local function optrequire(...)
    local success, module = pcall(require, ...)
    if success then
        return module
    end
end

local env -- forward declare for binding in metamethod
env = setmetatable({}, {
    __index = function(_, k)
        _ENV[k] = _ENV[k] or optrequire(k)
        return _ENV[k]
    end,
    __pairs = function(t)
        return function(_, key)
        local k, v = next(t, key)
        if not k and t == env then
            t = _ENV
            k, v = next(t)
        end
        if not k and t == _ENV then
            t = package.loaded
            k, v = next(t)
        end
        return k, v
        end
    end,
})

local function findTable(t, path)
    if type(t) ~= "table" then return nil end
    if not path or #path == 0 then return t end
    local name = string.match(path, "[^.]+")
    for k, v in pairs(t) do
    if k == name then
        return findTable(v, string.sub(path, #name + 2))
    end
    end
    local mt = getmetatable(t)
    if t == env then mt = {__index=_ENV} end
    if mt then
    return findTable(mt.__index, path)
    end
    return nil
end

function autoComplete(code)
    code = (code or "")
    local path = string.match(code, "[a-zA-Z_][a-zA-Z0-9_.]*$")
    if not path then return {} end
    local suffix = string.match(path, "[^.]+$") or ""
    local prefix = string.sub(path, 1, #path - #suffix)
    local tbl = findTable(env, prefix)
    if not tbl then return {} end
    local hints = {}

    for key, value in pairs(tbl or {}) do
        hints[key] = value
    end
    
    return hints
end


for key, value in pairs(autoComplete("print('Hello, World!')\nif true then component.ic2_te_mfsu.") or {}) do
    print(key.." - "..tostring(type(value)))
end
