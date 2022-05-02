local package = require("package")
local internet = require("internet")
local shell = require("shell")

local args, options = shell.parse(...)
local next, _, _ = pairs(args)
local _, host = next(args, 1)

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

local function findKeys(t, r, prefix, name)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
      if type(k) == "string" and string.match(k, "^"..name) then
        local typeOfElement = "p"
        if type(v) == "function" then typeOfElement = "f"
        elseif type(v) == "table" and getmetatable(v) and getmetatable(v).__call then typeOfElement = "f"
        elseif type(v) == "table" then typeOfElement = "p"
        end
        r[typeOfElement..k] = true
      end
    end
    local mt = getmetatable(t)
    if t == env then mt = {__index=_ENV} end
    if mt then
      return findKeys(mt.__index, r, prefix, name)
    end
  end

  local function autoComplete(code)
    code = (code or "")
    local path = string.match(code, "[a-zA-Z_][a-zA-Z0-9_.]*$")
    if not path then return {} end
    local suffix = string.match(path, "[^.]+$") or ""
    local prefix = string.sub(path, 1, #path - #suffix)
    local tbl = findTable(env, prefix)
    if not tbl then return {} end
    local keys = {}
    local hints = {}
    findKeys(tbl, keys, string.sub(code, 1, #code - #suffix), suffix)
    for key in pairs(keys) do
      table.insert(hints, key)
    end
    return hints
end


print("[OpenComputer IntelliSense] Connecting to "..host)
local handle = internet.open(host)

local function handleMessage(input)
    local out = ""
    for key, value in pairs(autoComplete(input)) do
        out = out..":"..value
    end
    handle:write(string.sub(out, 1).."\n")
end
local function main()
    while true do
        line = handle:read()
        handleMessage(line)
        os.sleep(0.1)
    end
end
local thread = require("thread")
thread.create(main):detach()
print("[OpenComputer IntelliSense] Detaching thread.. If anything went wrong, please reboot or kill the process manually.")
print("[OpenComputer IntelliSense] Kill command: ")

-- shell.execute("sh")
