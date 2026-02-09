--- 实现五三-五二复合顶功的 lua
--- 在指定的码位是五二顶，其余的是五三顶。

local snow = require "lutai.snow"

---@type table<string, boolean>
local pop52 = {
    ["ld"] = true,
    ["fy"] = true,
    ["uf"] = true,
    ["ff"] = true,
    ["fk"] = true,
    ["al"] = true,
    ["tl"] = true,
    ["gi"] = true,
    ["us"] = true,
    ["ka"] = true,
    ["si"] = true,
    ["uq"] = true,
    ["ua"] = true,
    ["vv"] = true,
    ["ui"] = true,
    ["jr"] = true,
    ["vz"] = true,
    ["sm"] = true,
    ["dm"] = true,
    ["ud"] = true,
    ["hs"] = true,
    ["fd"] = true,
    ["vs"] = true,
    ["ra"] = true,
    ["kl"] = true,
    ["ro"] = true,
    ["gy"] = true,
    ["kk"] = true,
    ["mq"] = true,
    ["fz"] = true,
    ["ts"] = true,
    ["wj"] = true
}


---@type table<string, number>
local select_keys = {
    ["space"] = 0,
    ["e"] = 1,
    ["x"] = 2,
    ["semicolon"] = 3,
    ["apostrophe"] = 4,
    ["7"] = 5,
    ["8"] = 6,
    ["9"] = 7,
}

local select_keys4 = {
    ["slash"] = 0,
    ["Tab"] = 0,
    ["2"] = 1,
    ["3"] = 2,
    ["4"] = 3,
    ["5"] = 4,
}

---@class MixEnv: Env
---@field dk_select boolean
---@field disable_dk table<string, boolean>

local this = {}

---@param env MixEnv
function this.init(env)
    env.dk_select = env.engine.schema.config:get_bool("translator/dk_select") or false
    env.disable_dk = {}
    local file = io.open(rime_api.get_user_data_dir() .. "/lua/lutai/disable_dk.txt", "r")
    if file then
        for line in file:lines() do
            env.disable_dk[line] = true
        end
        file:close()
    end
end

---@type table<string, table<string, boolean>>
local dkscope = {
    ["d"] = {},
    ["k"] = {}
}
for i = 1, 11 do
    dkscope["d"][("yuiophjklnm"):sub(i, i)] = true
end
for i = 1, 15 do
    dkscope["k"][("qwertasdfgzxcvb"):sub(i, i)] = true
end

---@param key_event KeyEvent
---@param env MixEnv
function this.func(key_event, env)
    if key_event:release() or key_event:alt() or key_event:ctrl() or key_event:caps() then
        return snow.kNoop
    end
    local context = env.engine.context
    local input = snow.current(context)
    local key = key_event:repr()
    if not input then
        return snow.kNoop
    end
    if key == "BackSpace" or key == "Escape" then
        return snow.kNoop
    end
    local p52 = pop52[input:sub(1, 2)]
    if rime_api.regex_match(input, "[qwrtyuiopasdfghjklzcvbnm]{1, 3}|fj[qwrtyuiopasdfghjklzcvbnm]{4}") then
        select = select_keys[key]
        if p52 and input:len() == 3 then
            if key == "Tab" or key == "slash" then
                context:commit()
                return snow.kAccepted
            end
            if env.dk_select then
                if (dkscope[key] or {})[input:sub(-1, -1)] and context:has_menu() then
                    context:commit()
                    return snow.kAccepted
                end
            end
            if string.match(key, "[qwrtyuiopasdfghjklzcvbnm]") ~= key or select then
                context:pop_input(1)
                context:commit()
                context:push_input(input:sub(3))
            end
            if select then
                context:select(select)
                context:commit()
                return snow.kAccepted
            end
        end
        if select then
            context:select(select)
            context:commit()
            return snow.kAccepted
        end
        if input:len() > 5 then
            context:commit()
        end
    elseif string.match(input, "[qwrtyuiopasdfghjklzcvbnm][qwrtyuiopasdfghjklzcvbnm][qwrtyuiopasdfghjklzcvbnm][qwrtyuiopasdfghjklzcvbnm]") == input then
        if input:sub(1, 2) == "fj" then
            return snow.kNoop
        end
        if env.dk_select then
            if (dkscope[key] or {})[input:sub(-1, -1)] and not env.disable_dk[input] and context:has_menu() then
                context:commit()
                return snow.kAccepted
            end
        end
        local select4 = select_keys4[key]
        if select4 then
            context:select(select4)
            return snow.kAccepted
        end
        if p52 then
            select = select_keys[key]
            context:pop_input(2)
            context:commit()
            context:push_input(input:sub(3))
            if select then
                context:select(select)
                context:commit()
                return snow.kAccepted
            end
        else
            select = select_keys[key]
            context:pop_input(1)
            context:commit()
            context:push_input(input:sub(4))
            if select then
                context:select(select)
                context:commit()
                return snow.kAccepted
            end
        end
    end
    return snow.kNoop
end

return this
