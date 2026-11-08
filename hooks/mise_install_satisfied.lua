local file = require("file")

--- Re-run PostInstall if a previous build left no vim binary.
function PLUGIN:MiseInstallSatisfied(ctx)
    if file.exists(file.join_path(ctx.path, "bin", "vim")) then
        return true
    end
    return { satisfied = false, reason = "bin/vim is missing" }
end
