---露台・二四顶・词语过滤器
---如果 aaaa 有词语，那么只保留词语

local snow = require "lutai.snow"

---@param input Translation
---@param env Env
local function abbrev_filter(input, env)
    local current = snow.current(env.engine.context)
    if not current then
        return
    end
    ---把非四码和反查按原样输出
    if #current ~= 4 or current:sub(1, 1) == 'x' then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end
    ---@type Candidate[]
    local abbrevs = {}
    ---@type Candidate[]
    local all = {}
    for cand in input:iter() do
        if cand.type == "abbrev" then
            table.insert(abbrevs, cand)
        end
        table.insert(all, cand)
    end
    local hasabbrevs = false
    for _, cand in ipairs(abbrevs) do
        hasabbrevs = true
        yield(cand)
    end
    if not hasabbrevs then
        for _, cand in ipairs(all) do
            yield(cand)
        end
    end
end

return abbrev_filter
