---露台・二四顶・词语略码翻译器
---如果 aaaa 是某个词语的略码，那么将 aaaa 翻译为词语

---@class AbbrevEnv: Env
---@field tofull LevelDb
---@field toshort LevelDb
---@field memory Memory

local abbrev_translator = {}

---@type table<string, LevelDb>
_db_pool= _db_pool or {}

---@param dbname string
---@param mode boolean
---@return LevelDb
local function wrapLevelDb(dbname, mode)
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]
    if db and not db:loaded() then
        if mode then
            db:open()
        else
            db:open_read_only()
        end
    end
    return db
end

---@param env AbbrevEnv
function abbrev_translator.init(env)
    env.tofull = wrapLevelDb("tofull")
    env.memory = Memory(env.engine, env.engine.schema)
end

---@param input string
---@param segment Segment
---@param env AbbrevEnv
function abbrev_translator.func(input, segment, env)
    if input:len() ~= 4 then
        return
    end
    for _, full in env.tofull:query(input):iter() do
        env.memory:user_lookup(full, false)
        for entry in env.memory:iter_user() do
            local phrase = Phrase(env.memory, "abbrev", segment.start, segment._end, entry)
            yield(phrase:toCandidate())
        end
    end
end

---@param env AbbrevEnv
function abbrev_translator.fini(env)
    env.tofull:close()
    env.tofull = nil
    env.memory:disconnect()
    env.memory = nil
end

return abbrev_translator
