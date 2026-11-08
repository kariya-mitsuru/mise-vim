local cmd = require("cmd")
local http = require("http")

local REPO = "https://github.com/vim/vim"

-- Release dates are only needed for versions near the minimum_release_age
-- cutoff (default 24h): mise never hides an undated version, so older tags
-- can stay undated. Dates are read from GitHub's tags Atom feed (10 tags per
-- page, no API token / rate limit; uncached pages can take ~2s each) until
-- this many days are covered. Raise MISE_VIM_DATE_WINDOW_DAYS if you set
-- minimum_release_age longer than the default window.
local DATE_WINDOW_DAYS = tonumber(os.getenv("MISE_VIM_DATE_WINDOW_DAYS") or "") or 3
local MAX_FEED_PAGES = math.max(1, math.ceil(DATE_WINDOW_DAYS * 1.5))

local function parts(v)
    local t = {}
    for n in v:gmatch("%d+") do
        table.insert(t, tonumber(n))
    end
    return t
end

local function newer(a, b)
    local pa, pb = parts(a), parts(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or -1, pb[i] or -1
        if x ~= y then
            return x > y
        end
    end
    return false
end

--- Returns { ["9.2.1302"] = "2026-11-05T21:52:12Z", ... } for recent tags.
--- Failures are not fatal: versions are then just listed without dates.
local function recent_tag_dates()
    local dates = {}
    -- RFC 3339 UTC strings compare correctly as plain strings.
    local ok, oldest_wanted = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ", os.time() - DATE_WINDOW_DAYS * 86400)
    if not ok then
        oldest_wanted = nil
    end

    local after = nil
    for _ = 1, MAX_FEED_PAGES do
        local url = REPO .. "/tags.atom" .. (after and ("?after=v" .. after) or "")
        local resp = http.try_get({ url = url })
        if not resp or resp.status_code ~= 200 or not resp.body then
            break
        end

        local last_version, last_date = nil, nil
        for entry in resp.body:gmatch("<entry>(.-)</entry>") do
            local version = entry:match("<title>v([%d%.]+)</title>")
            local date = entry:match("<updated>([^<]+)</updated>")
            if version and date then
                dates[version] = date
                last_version, last_date = version, date
            end
        end

        if not last_version or (oldest_wanted and last_date < oldest_wanted) then
            break
        end
        after = last_version
    end
    return dates
end

--- Lists numeric release tags of vim/vim (v9.1.1234, v8.2.0000, v7.4 ...), newest first.
function PLUGIN:Available(ctx)
    local out = cmd.exec("git ls-remote --tags --refs " .. REPO .. ".git")
    local versions = {}
    for tag in out:gmatch("refs/tags/v([%d%.]+)%s") do
        -- the pattern already skips tags with letters such as "7.0b01"
        if tag:match("^%d+%.%d+[%.%d]*$") then
            table.insert(versions, tag)
        end
    end
    table.sort(versions, newer)

    local dates = recent_tag_dates()
    local result = {}
    for _, v in ipairs(versions) do
        table.insert(result, { version = v, created_at = dates[v] })
    end
    return result
end
