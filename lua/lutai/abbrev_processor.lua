--- 露台・二四顶・造词删词处理器
--- 负责将 8a+( 8a+) 的造词编码生成略码并加入 lutaiesToFull.txt 中，或删除记录中的略码

local snow = require "lutai.snow"

local abbrev_processor = {}

---@type LevelDb?
LutaiesToFull = LutaiesToFull
---@type integer
LutaiesToFullReference = LutaiesToFullReference or 0

---@param c integer
---@return string
local function extra(c)
    return string.format("c=%d d=0 t=1", c)
end

---@param env Env
function abbrev_processor.init(env)
    if LutaiesToFull ~= nil then
        return
    end
    LutaiesToFull = LevelDb("lutaies_to_full")
    LutaiesToFull:open()
    LutaiesToFullReference = LutaiesToFullReference + 1
end

---@param short string
---@param full string
local function update(short, full)
    local c = 0
    for key, value in LutaiesToFull:query(short):iter() do
        local key_full = key:match("\t([%a 8]+)$")
        ---@type integer
        local key_c = value:match("c=(%-?%d+)") + 0
        if key_full == full then
            c = key_c
        end
        if key_c > 0 then
            LutaiesToFull:update(string.format("%s \t%s", short, key_full), extra(-key_c))
        end
    end
    LutaiesToFull:update(string.format("%s \t%s", short, full), extra(math.abs(c) + 1))
end

---@param short string
---@param full string
local function delete(short, full)
    for key, value in LutaiesToFull:query(short):iter() do
        local key_full = key:match("\t([%a 8]+)$")
        local c = value:match("c=(%-?%d+)") + 0
        if key_full == full then
            LutaiesToFull:update(key, extra(-c))
        end
    end
end



---@param key_event KeyEvent
---@param env Env
function abbrev_processor.func(key_event, env)
    if key_event:release() or key_event:alt() or key_event:ctrl() or key_event:caps() then
        return snow.kNoop
    end
    local input = env.engine.context:get_script_text()
    if not input then
        return snow.kNoop
    end
    if input:sub(1, 1) == "8" then
        local space, _ = input:find(" ")
        local shortcode = ""
        if space then
            shortcode = input:sub(2, 3) .. input:sub(space + 2, space + 3)
        end
        if key_event:repr() == "space" then
            update(shortcode, input)
        elseif key_event:shift() and key_event:repr() == "Delete" then
            delete(shortcode, input)
        end
        return snow.kNoop
    elseif input:len() == 5 then
        if not key_event:shift() or key_event.keycode ~= "Delete" then
            return snow.kNoop
        end
        delete(input:sub(1, 2) .. input:sub(4, 5), input)
    end
    return snow.kNoop
end

---@param env AbbrevEnv
function abbrev_processor.fini(env)
    LutaiesToFullReference = LutaiesToFullReference - 1
    if LutaiesToFullReference == 0 then
        LutaiesToFull:close()
    end
end

return abbrev_processor
