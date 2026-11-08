local cmd = require("cmd")

--- Lists numeric release tags of vim/vim (v9.1.1234, v8.2.0000, v7.4 ...), newest first.
function PLUGIN:Available(ctx)
    local out = cmd.exec("git ls-remote --tags --refs https://github.com/vim/vim.git")
    local versions = {}
    for tag in out:gmatch("refs/tags/v([%d%.]+)%s") do
        -- skip odd tags such as "7.0b01" (pattern already excludes letters)
        if tag:match("^%d+%.%d+[%.%d]*$") then
            table.insert(versions, tag)
        end
    end

    local function parts(v)
        local t = {}
        for n in v:gmatch("%d+") do
            table.insert(t, tonumber(n))
        end
        return t
    end
    table.sort(versions, function(a, b)
        local pa, pb = parts(a), parts(b)
        for i = 1, math.max(#pa, #pb) do
            local x, y = pa[i] or -1, pb[i] or -1
            if x ~= y then
                return x > y
            end
        end
        return false
    end)

    local result = {}
    for _, v in ipairs(versions) do
        table.insert(result, { version = v })
    end
    return result
end
