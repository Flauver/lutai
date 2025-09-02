---回头补码处理器

local snow = require "lutai.snow"

---@param key_event KeyEvent
---@param env Env
local function editor(key_event, env)
    local context = env.engine.context
    if key_event.modifier > 0 then
        return snow.kNoop
    end
    local incoming = key_event:repr()
    ---补码的格式是 d[a-z]，只处理匹配这个格式的编码和退格
    if not (rime_api.regex_match(incoming, "[a-z]") or incoming == "BackSpace") then
        return snow.kNoop
    end
    -- 判断是否满足补码条件：末音节有 3 码，且前面至少还有一个音节
    -- confirmed_position 是拼音整句中已经被确认的编码的长度，只有后面的部分是可编辑的
    -- current_input 获取的是这部分的编码
    -- 这样，我们就可以在拼音整句中多次应用补码，而不会影响到已经确认的部分
    local confirmed_position = context.composition:toSegmentation():get_confirmed_position()
    local previous_caret_pos = context.caret_pos
    local current_input = context.input:sub(confirmed_position + 1, previous_caret_pos)
    if not rime_api.regex_match(current_input, ".{2,}[qwertyuiopasfghjklzxcvbnm][a-z]d[a-z]") then
        return snow.kNoop
    end
    -- 如果输入不是 d，还要验证是否有补码
    if incoming ~= "d" then
        if not rime_api.regex_match(current_input, "[qwertyuiopasfghjklzxcvbnm][a-z]d.+") then
            return snow.kNoop
        end
    end
    -- 找出补码的位置（第一个音节之后），并添加补码
    local first_char_code_len = rime_api.regex_search(current_input, "[qwertyuiopasfghjklzxcvbnm][a-z](?:d[a-z])?")[1]:len()
    if current_input:len() % 2 == 1 then
        -- 举个例子：比如“你们”输入到“nidmfdf”，但是这个正则不知道该怎么写才能匹配到 nid，只能匹配到 nidm，所以只能再判断输入的长度
        first_char_code_len = first_char_code_len - 1
    end
    context.caret_pos = confirmed_position + first_char_code_len
    if incoming == "BackSpace" then
        context:pop_input(1)
        first_char_code_len = first_char_code_len - 1
    else
        context:push_input(incoming)
        first_char_code_len = first_char_code_len + 1
    end
    -- 如果补码后不到 5 码，则返回当前的位置，使得补码后的输入可以继续匹配词语；
    -- 如果补码后已有 5 码，则不返回，相当于进入单字模式
    if first_char_code_len < 5 then
        context.caret_pos = previous_caret_pos + 1
    end
    return snow.kAccepted
end

return editor
