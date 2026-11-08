local cmd = require("cmd")
local file = require("file")
local http = require("http")

-- Same defaults as the mise-plugins/mise-vim asdf plugin (compiledby changed).
-- The *interp=yes options are skipped silently when the dev package is missing.
local DEFAULT_CONFIG = table.concat({
    "--with-tlib=ncurses",
    "--with-compiledby=mise",
    "--enable-multibyte",
    "--enable-cscope",
    "--enable-terminal",
    "--enable-perlinterp",
    "--enable-rubyinterp",
    "--enable-python3interp",
    "--enable-luainterp",
    "--enable-gui=no",
    "--without-x",
}, " ")

local GUI_VALUES = {
    auto = true, no = true, gtk2 = true, gnome2 = true, gtk3 = true,
    gtk4 = true, motif = true, haiku = true, photon = true, carbon = true,
}

local function sh_quote(s)
    return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

local function opt(options, key)
    local v = options and options[key]
    if v == nil or v == "" then
        return nil
    end
    return tostring(v)
end

--- Downloads the source tarball to a temporary directory, then
--- ./configure --prefix=<install dir> && make && make install.
---
--- The version is a release tag without "v" (9.2.1302), or "ref:<git ref>"
--- (ref:master, ref:<commit sha>) to build any branch, tag or commit.
---
--- Tool options (mise.toml), same defaults as asdf-vim:
---   features          tiny|normal|huge   (default "huge")      ASDF_VIM_TYPE
---   configure_options configure args (default: DEFAULT_CONFIG below)   ASDF_VIM_CONFIG
---   gui               --enable-gui=<value>, overrides the one in configure_options
---   jobs              make -j value       (default: nproc)
function PLUGIN:PostInstall(ctx)
    local version = ctx.runtimeVersion
    local prefix = ctx.rootPath
    local options = ctx.options or {}

    local features = opt(options, "features") or "huge"
    local config = opt(options, "configure_options") or DEFAULT_CONFIG
    local gui = opt(options, "gui")
    if gui and not GUI_VALUES[gui] then
        error("unsupported gui value: " .. gui)
    end

    local jobs = opt(options, "jobs")
        or cmd.exec("nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1"):match("%d+")
        or "1"
    if not jobs:match("^%d+$") then
        error("jobs must be a number: " .. jobs)
    end

    -- Note: pcall cannot wrap http.* calls in mise's Lua runtime, so cleanup
    -- is done explicitly on the download error path and by a shell trap below.
    local work = cmd.exec("mktemp -d"):gsub("%s+$", "")
    local tarball = file.join_path(work, "vim.tar.gz")
    local url
    local ref = version:match("^ref:(.+)$")
    if ref then
        -- vim@ref:<branch|tag|commit>: GitHub source archive (includes configure)
        if not ref:match("^[%w%._/-]+$") then
            cmd.exec("rm -rf " .. sh_quote(work))
            error("invalid git ref: " .. ref)
        end
        url = "https://github.com/vim/vim/archive/" .. ref .. ".tar.gz"
    else
        url = "https://github.com/vim/vim/archive/refs/tags/v" .. version .. ".tar.gz"
    end

    print("Downloading " .. url)
    local dl_err = http.download_file({ url = url }, tarball)
    if dl_err ~= nil then
        cmd.exec("rm -rf " .. sh_quote(work))
        error("download failed: " .. tostring(dl_err))
    end

    local args = "--prefix=" .. sh_quote(prefix) .. " --with-features=" .. sh_quote(features) .. " " .. config
    if gui then
        args = args .. " --enable-gui=" .. gui
    end

    print("Building vim " .. version .. " (configure " .. args .. ", make -j " .. jobs .. ")")
    local script = table.concat({
        "set -e",
        "work=" .. sh_quote(work),
        "trap 'rm -rf \"$work\"' EXIT",
        "cd \"$work\"",
        -- the top-level directory name depends on the ref, so strip it
        "mkdir src && tar -xzf vim.tar.gz -C src --strip-components=1",
        "cd src",
        "./configure " .. args .. " >configure.out 2>&1 || { tail -n 50 configure.out >&2; exit 1; }",
        "make -j " .. jobs .. " >make.out 2>&1 || { tail -n 50 make.out >&2; exit 1; }",
        "make install >install.out 2>&1 || { tail -n 50 install.out >&2; exit 1; }",
    }, "\n")
    cmd.exec(script)

    if not file.exists(file.join_path(prefix, "bin", "vim")) then
        error("build finished but bin/vim was not installed")
    end
end
