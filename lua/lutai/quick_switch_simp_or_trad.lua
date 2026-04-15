-- 快捷切换简繁

local snow = require "lutai.snow"

local this = {}

---@param env Env
function this.init(env)
    env.engine.context.commit_notifier:connect(function (ctx)
        local candidate = ctx.commit_history:back()
        if candidate == nil then return end
        if candidate.type == "quick_to_simp" then
            ctx:set_option("simplify", true)
            ctx:set_option("traditionalize", false)
        elseif candidate.type == "quick_to_trad" then
            ctx:set_option("simplify", false)
            ctx:set_option("traditionalize", true)
        end
    end)
end

---@param input string
---@param seg Segment
---@param env Env
function this.func(input, seg, env)
    if input == "oj_t" then
        yield(Candidate("quick_to_simp", seg.start, seg._end, "", "转简体"))
    elseif input == "of_t" then
        yield(Candidate("quick_to_trad", seg.start, seg._end, "", "轉繁體"))
    end
end

return this
