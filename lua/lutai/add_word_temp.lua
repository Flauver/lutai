local snow = require "lutai.snow"

---@class EnvA: Env
---@field reverse ReverseLookup

local proc = {}

---@type table<string, string[]>
local data2 = {}
---@type table<string, string[]>
local data = {}

---@type fun(phrase: string, length: integer, datap: table<string, string[]>, env: EnvA)
local encode

---@param env EnvA
function proc.init(env)
    env.reverse = ReverseLookup("lutai")
    local auto_add_word = env.engine.schema.config:get_bool("translator/auto_add_word") or true
    if auto_add_word then
        env.engine.context.commit_notifier:connect(function (ctx)
            local i = 0
            local phrase = ""
            for _, entry in ctx.commit_history:iter() do
                if entry.type == "raw" then
                    goto continue
                end
                i = i + 1
                if entry.type == "punct" then
                    break
                end
                if i - 1 == 4 then
                    break
                end
                phrase = entry.text .. phrase
                local length = utf8.len(phrase)
                if length ~= 1 and length ~= nil then
                    encode(phrase, length, data2, env)
                end
                ::continue::
            end
        end)
    end
end

---@param code string
---@param length integer
---@return string?
local function rule(code, length)
    local s = "ru"
    ---@type table<string, fun(): string>
    local _switch = {
        [2] = function ()
          return code
        end,
        [3] = function ()
          return code .. s:sub(1, 1)
        end,
        [4] = function ()
          return code .. s:sub(2, 2)
        end
    }
    local f = _switch[length]
    if f then return f() end
end

encode = function(phrase, length, datap, env)
  local translations = env.reverse:lookup(snow.sub(phrase, 1, 1))
  for stem in translations:gmatch("[^ ]+") do
    if #stem < 2 then
      goto continue
    end
    local encoded = rule(stem, length)
    if encoded then
        datap[encoded] = datap[encoded] or {}
        local list = {}
        for _, w in ipairs(datap[encoded]) do
            if w ~= phrase then
                table.insert(list, w)
            end
        end
        table.insert(list, phrase)
        datap[encoded] = list
    end
    ::continue::
  end
end

---@param key_event KeyEvent
---@param env EnvA
function proc.func(key_event, env)
    if key_event:repr() == "Control+j" then
        local i = 0
        local phrase = ""
        for _, entry in env.engine.context.commit_history:iter() do
            if entry.type == "raw" then
                goto continue
            end
            i = i + 1
            if entry.type == "punct" then
                break
            end
            if i - 1 == 4 then
                break
            end
            phrase = entry.text .. phrase
            local length = utf8.len(phrase)
            if length ~= 1 and length ~= nil then
                encode(phrase, length, data, env)
            end
            ::continue::
        end
        return snow.kAccepted
    end
    return snow.kNoop
end

---@param input string
---@param seg Segment
---@param env EnvA
local function tran(input, seg, env)
    if input:sub(1, 1) == "[" then
        local words = {}
        for _, word in ipairs(data2[input:sub(2)] or {}) do
            table.insert(words, word)
        end
        for _, word in ipairs(data[input:sub(2)] or {}) do
            table.insert(words, word)
        end
        for i = 1, #words do
            yield(Candidate("temp", seg.start, seg._end, words[#words - i + 1], ""))
        end
    end
end

return {
    proc = proc,
    tran = tran
}
