local wm = require("windows")


local M = {
}

function M.setup(opts)
    M.config = opts or {

        style={
            width=0.5
        },
        layout = {
            file_explorer = "left"
        }
    }
    wm.init_window(M.config.style.width)
    wm.window_listener_setup()
    if M.config.layout.file_explorer == "left" then
        wm.init_file_explorer(wm.windows.left_window.win_id)
    end


end



return M