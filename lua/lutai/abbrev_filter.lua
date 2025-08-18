---露台・二四顶・词语过滤器
---如果 aaaa 有词语，那么只保留词语

---@param input Translation
local function abbrev_filter(input)
    ---@type table<number, Candidate>
    local abbrevs = {}
    ---@type table<number, Candidate>
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
