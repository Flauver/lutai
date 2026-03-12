--- 露台・二四顶・词语略码翻译器
--- 如果 aaaa 是某个词语的略码，那么将 aaaa 翻译为词语

---@class AbbrevEnv: Env
---@field memory Memory

local abbrev_translator = {}

---@type LevelDb?
LutaiesToFull = LutaiesToFull
---@type integer
LutaiesToFullReference = LutaiesToFullReference or 0

---@param env AbbrevEnv
function abbrev_translator.init(env)
    if LutaiesToFull == nil then
        LutaiesToFull = LevelDb("lutaies_to_full")
        LutaiesToFull:open()
    end
    LutaiesToFullReference = LutaiesToFullReference + 1
    env.memory = Memory(env.engine, env.engine.schema)
end

---@param input string
---@param segment Segment
---@param env AbbrevEnv
function abbrev_translator.func(input, segment, env)
    if input:len() ~= 4 then
        return
    end
    local full = ""
    for key, value in LutaiesToFull:query(input):iter() do
        local key_full = key:match("\t([%a 8]+)$")
        ---@type integer
        local key_c = value:match("c=(%-?%d+)") + 0
        if key_c > 0 then
            full = key_full
        end
    end
    env.memory:user_lookup(full, false)
    for entry in env.memory:iter_user() do
        local phrase = Phrase(env.memory, "abbrev", segment.start, segment._end, entry)
        yield(phrase:toCandidate())
    end
end

---@param env AbbrevEnv
function abbrev_translator.fini(env)
    env.memory:disconnect()
    env.memory = nil
    LutaiesToFullReference = LutaiesToFullReference - 1
    if LutaiesToFullReference == 0 then
        LutaiesToFull:close()
        LutaiesToFull = nil
    end
end

return abbrev_translator
