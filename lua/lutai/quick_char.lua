local snow = require "lutai.snow"

---@class QuickCharEnv: Env
---@field reverse ReverseLookup

local this = {}

---@type table<string, string>
local data = {}

---@param env QuickCharEnv
function this.init(env)
    env.reverse = ReverseLookup("lutai")
    env.engine.context.commit_notifier:connect(function (ctx)
        for _, entry in ctx.commit_history:iter() do
            for _, code in utf8.codes(entry.text) do
                for partial_code in env.reverse:lookup(utf8.char(code)):gmatch("[^ ]+") do
                    if partial_code == nil then
                        break
                    end
                    data[partial_code:sub(1, 1)] = utf8.char(code)
                end
            end
            break
        end
    end)
end

---@param key_event KeyEvent
---@param env QuickCharEnv
function this.func(key_event, env)
    local context = env.engine.context
    local input = snow.current(context)
    if key_event:repr() == "8" then
        env.engine:process_key(KeyEvent("space"))
        context:push_input("8")
        return snow.kAccepted
    end
    if input ~= "8" or key_event:alt() or key_event:caps() or key_event:ctrl() or key_event:release() then
        return snow.kNoop
    end
    local ok, key = pcall(string.char, key_event.keycode)
    if not ok then
        return snow.kNoop
    end
    local char = data[key]
    if not char then
        return snow.kNoop
    end
    context:clear()
    env.engine:commit_text(char)
    return snow.kAccepted

end

return this
