local snow = require "lutai.snow"

---@class EnvA: Env
---@field reverse ReverseLookup
---@field wordpairs ReverseLookup

local proc = {}

---@type table<string, string[]>
local data = {} -- 按 Control + j 加的词
---@type table<string, string[]>
local data2 = {} -- 自动加的词
---@type table<string, string[]>
local data3 = {} -- 自动加的词，但是发现这个词的最后一个字和下一个条目的第一个字，能组成一个词（或的一部分），所以它很可能不是词

---@type fun(phrase: string, length: integer, datap: table<string, string[]>, env: EnvA)
local encode

---@param env EnvA
function proc.init(env)
    env.reverse = ReverseLookup("lutai")
    env.wordpairs = ReverseLookup("lutai_wordpairs")
    local auto_add_word = env.engine.schema.config:get_bool("translator/auto_add_word") or true
    if auto_add_word then
        env.engine.context.commit_notifier:connect(function (ctx)
            local phrase = ""
            ---@type string?
            local last = nil
            ---@type string?
            local pair = nil
            for _, entry in env.engine.context.commit_history:iter() do
                if entry.type == "raw" then
                    goto continue
                end
                if not last then
                    last = entry.text
                    goto continue
                end
                if entry.type == "punct" then
                    break
                end
                if utf8.len(phrase) > 4 then
                    break
                end
                phrase = entry.text .. phrase
                if not pair then
                    pair = snow.sub(phrase, -1, -1) .. snow.sub(last, 1, 1)
                end
                local length = utf8.len(phrase)
                if length ~= 1 and length ~= nil then
                    if env.wordpairs:lookup(pair) ~= "" then
                        encode(phrase, length, data3, env)
                    else
                        encode(phrase, length, data2, env)
                    end
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
        local phrase = ""
        for _, entry in env.engine.context.commit_history:iter() do
            if entry.type == "raw" then
                goto continue
            end
            if entry.type == "punct" then
                break
            end
            if utf8.len(phrase) > 4 then
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
    elseif key_event:repr() == "bracketleft" then
        env.engine.context:commit()
        env.engine.context:push_input("[")
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
        for _, word in ipairs(data3[input:sub(2)] or {}) do
            table.insert(words, word)
        end
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
