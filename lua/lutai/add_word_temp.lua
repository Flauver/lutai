local snow = require "lutai.snow"

---@class EnvA: Env
---@field reverse ReverseLookup

local proc = {}

---@type table<string, string[]>
local data = {}

---@param env EnvA
function proc.init(env)
    env.reverse = ReverseLookup("lutai")
end

---@param code string[]
---@return string?
local function rule(code)
    local s = "ru"
    ---@type table<string, fun(): string>
    local _switch = {
        [2] = function ()
          return code[1]
        end,
        [3] = function ()
          return code[1] .. s:sub(1, 1)
        end,
        [4] = function ()
          return code[1] .. s:sub(2, 2)
        end
    }
    local f = _switch[#code]
    if f then return f() end
end

---@param phrase string
---@param pos integer
---@param code string[]
---@param env EnvA
local function dfs_encode(phrase, pos, code, env)
  if pos > utf8.len(phrase) then
    local encoded = rule(code)
    if encoded then
        data[encoded] = data[encoded] or {}
        local list = {}
        for _, w in ipairs(data[encoded]) do
            if w ~= phrase then
                table.insert(list, w)
            end
        end
        table.insert(list, phrase)
        data[encoded] = list
      return
    end
  end
  local translations = env.reverse:lookup(snow.sub(phrase, pos, pos))
  ---@type table<string, boolean>
  local exist = {}
  for stem in translations:gmatch("[^ ]+") do
    if #stem < 2 then
      goto continue
    end
    table.insert(code, stem)
    dfs_encode(phrase, pos + 1, code, env)
    table.remove(code)
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
            if utf8.len(phrase) ~= 1 then
                local code = {}
                dfs_encode(phrase, 1, code, env)
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
