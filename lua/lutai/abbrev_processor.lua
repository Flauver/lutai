---露台・二四顶・造词删词处理器
---负责将 8a+( 8a+) 的造词编码生成略码并加入数据库中，或删除数据库中的略码

local snow = require "lutai.snow"

local abbrev_processor = {}

---@class AbbrevEnv: Env
---@field tofull LevelDb
---@field toshort LevelDb

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
function abbrev_processor.init(env)
    env.tofull = wrapLevelDb("tofull", true)
    env.toshort = wrapLevelDb("toshort", true)
end



---@param key_event KeyEvent
---@param env AbbrevEnv
function abbrev_processor.func(key_event, env)
    if key_event:release() or key_event:alt() or key_event:ctrl() or key_event:caps() then
        return snow.kNoop
    end
    local input = env.engine.context:get_script_text()
    if not input then
        return snow.kNoop
    end
    if input:sub(1, 1) == "8" then
        if key_event:repr() == "space" then
            local space, _ = input:find(" ")
            local shortcode = input:sub(2, 3) .. input:sub(space + 2, space + 3)
            env.tofull:update(shortcode, input)
            env.toshort:update(input, shortcode)
        elseif key_event:shift() and key_event:repr() == "Delete" then
            for _, short in env.toshort:query(input):iter() do
                env.toshort:erase(short)
            end
            env.tofull:erase(input)
        end
        return snow.kNoop
    elseif input:len() == 4 then
        if not key_event:shift() and key_event.keycode ~= "Delete" then
            return snow.kNoop
        end
        for _, full in env.tofull:query(input):iter() do
            env.toshort:erase(full)
        end
        env.tofull:erase(input)
    end
    return snow.kNoop
end

---@param env AbbrevEnv
function abbrev_processor.fini(env)
    env.tofull:close()
    env.tofull = nil
    env.toshort:close()
    env.tofull = nil
end

return abbrev_processor
