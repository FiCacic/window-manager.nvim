local wm = require("windows")


local M = {
}




print("LOADING LUA")
function M.setup(opts)
    M.config = opts or {

        style={
            width=0.5
        },
        layouy = {
            file_explorer = "left"
        }
    }
    wm.init_window(opts.style.width)

    if opts.layout.file_explorer == "left" then
        wm.init_file_explorer(wm.windows.left_window.win_id)
    end

end



return M