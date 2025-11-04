--- 当此码位为五二顶时，提示

local snow = require "lutai.snow"

---@type table<string, boolean>
local pop52 = {
    ["ld"] = true,
    ["fy"] = true,
    ["uf"] = true,
    ["ff"] = true,
    ["fk"] = true,
    ["al"] = true,
    ["tl"] = true,
    ["gi"] = true,
    ["us"] = true,
    ["ka"] = true,
    ["si"] = true,
    ["uq"] = true,
    ["ua"] = true,
    ["vv"] = true,
    ["ui"] = true,
    ["jr"] = true,
    ["vz"] = true,
    ["sm"] = true,
    ["dm"] = true,
    ["ud"] = true,
    ["hs"] = true,
    ["fd"] = true,
    ["vs"] = true,
    ["ra"] = true,
    ["kl"] = true,
    ["ro"] = true,
    ["gy"] = true,
    ["kk"] = true,
    ["mq"] = true,
    ["fz"] = true,
    ["ts"] = true,
    ["wj"] = true
}

---@param translation Translation
---@param env Env
local function pop52tips(translation, env)
    for v in translation:iter() do
        yield(v)
    end
    local context = env.engine.context
    local current = snow.current(context)
    local code = (current and current ~= "") and current or context:get_script_text()
    if not code or not pop52[code:sub(1, 2)] then
        return
    end
    local cand = env.engine.context:get_selected_candidate()
    if not cand then
        return
    end
    cand.preedit = "五二顶：" .. cand.preedit
end

return pop52tips
