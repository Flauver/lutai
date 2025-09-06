---露台・二四顶・造词删词处理器
---负责将 8a+( 8a+) 的造词编码生成略码并加入 lutaiesToFull.txt 中，或删除记录中的略码

local snow = require "lutai.snow"

local abbrev_processor = {}

---@type table<string, string> | nil
LutaiesToFull = LutaiesToFull

---@param env Env
function abbrev_processor.init(env)
    if LutaiesToFull ~= nil then
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
end

---@param short string
---@param full string | nil
local function update(short, full)
    LutaiesToFull[short] = full
    local path = rime_api.get_user_data_dir() .. "/lutaiesToFull.txt"
    local file = io.open(path, "w")
    if not file then
        return
    end
    local text = ""
    if not LutaiesToFull then
        return
    end
    for _short, _full in pairs(LutaiesToFull) do
        if not _full then
            goto continue
        end
        text = text .. _short .. "\t" .. _full .. "\n"
        ::continue::
    end
    text = text:sub(1, -2)
    file:write(text)
    file:close()
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
        local shortcode = input:sub(2, 3) .. input:sub(space + 2, space + 3)
        if key_event:repr() == "space" then
            update(shortcode, input)
        elseif key_event:shift() and key_event:repr() == "Delete" then
            LutaiesToFull[shortcode] = nil
        end
        return snow.kNoop
    elseif input:len() == 5 then
        if not key_event:shift() or key_event.keycode ~= "Delete" then
            return snow.kNoop
        end
        LutaiesToFull[input:sub(1, 2) .. input:sub(4, 5)] = nil
    end
    return snow.kNoop
end

---@param env AbbrevEnv
function abbrev_processor.fini(env)
end

return abbrev_processor
