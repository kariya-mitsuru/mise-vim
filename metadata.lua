--- mise tool plugin: build Vim from source
PLUGIN = {}

PLUGIN.name = "vim"
PLUGIN.version = "0.1.0"
PLUGIN.description = "Build and install Vim from source (github.com/vim/vim)"
PLUGIN.author = "Mitsuru Kariya"
PLUGIN.license = "MIT"
PLUGIN.homepage = "https://www.vim.org/"

-- Checked by mise before install. Missing ones are reported / installed
-- according to the `system_deps` setting.
PLUGIN.systemDependencies = {
    { bin = "cc", packages = { apt = "gcc", dnf = "gcc", zypper = "gcc", pacman = "gcc", apk = "gcc" } },
    { bin = "tar", packages = { apt = "tar", dnf = "tar", zypper = "tar", pacman = "tar", apk = "tar" } },
    { bin = "make", packages = { apt = "make", dnf = "make", zypper = "make", pacman = "make", apk = "make", brew = "make" } },
    {
        pkgconfig = "ncursesw",
        packages = {
            apt = "libncurses-dev",
            dnf = "ncurses-devel",
            zypper = "ncurses-devel",
            pacman = "ncurses",
            apk = "ncurses-dev",
            brew = "ncurses",
        },
    },
    -- Optional: interpreters enabled by the default configure options.
    {
        command = "perl -MExtUtils::Embed -e 1",
        optional = "+perl",
        packages = { apt = "libperl-dev", dnf = "perl-ExtUtils-Embed", zypper = "perl", pacman = "perl" },
    },
    {
        pkgconfig = "python3-embed",
        optional = "+python3",
        packages = { apt = "python3-dev", dnf = "python3-devel", zypper = "python3-devel", pacman = "python", brew = "python" },
    },
    {
        command = [[ruby -rrbconfig -e 'exit File.exist?(File.join(RbConfig::CONFIG["rubyhdrdir"], "ruby.h"))']],
        optional = "+ruby",
        packages = { apt = "ruby-dev", dnf = "ruby-devel", zypper = "ruby-devel", pacman = "ruby", brew = "ruby" },
    },
    {
        pkgconfig = "lua",
        optional = "+lua",
        packages = { apt = "liblua5.4-dev", dnf = "lua-devel", zypper = "lua54-devel", pacman = "lua", brew = "lua" },
    },
}
