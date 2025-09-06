---露台・二四顶・词语略码翻译器
---如果 aaaa 是某个词语的略码，那么将 aaaa 翻译为词语

---@class AbbrevEnv: Env
---@field memory Memory

local abbrev_translator = {}

---@type table<string, string> | nil
LutaiesToFull = LutaiesToFull

---@param env AbbrevEnv
function abbrev_translator.init(env)
    if LutaiesToFull ~= nil then
        env.memory = Memory(env.engine, env.engine.schema)
        return
    end
    LutaiesToFull = {}
    local path = rime_api.get_user_data_dir() .. "/lutaiesToFull.txt"
    local file = io.open(path, "r")
    if not file then
        return
    end
    for line in file:lines() do
        ---@type string, string
        local short, full = line:match("([^\t]+)\t([^\t]+)")
        if not short or not full then
            goto continue
        end
        LutaiesToFull[short] = full
        ::continue::
    end
    file:close()
    env.memory = Memory(env.engine, env.engine.schema)
end

---@param input string
---@param segment Segment
---@param env AbbrevEnv
function abbrev_translator.func(input, segment, env)
    if input:len() ~= 4 then
        return
    end
    local full = LutaiesToFull[input]
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
end

return abbrev_translator
