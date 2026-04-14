
local HEIGHT_ORIENTATION = 1
local WIDTH_ORIENTATION = 0


local function HELP_FUNCTION()



end


local function buffer_props(id,title,win_id)


    return {
        id=id,
        title=title,
        window=win_id,
        active = false
    }
end

local function child_win_props()
    return{
        collapsed=false
    }
end

local function create_win_props()

    return {
        current_buffer_index = 1,
        buffers = {
            
            {
                id=-1,
                title="No title",
                win_id=-1,
                active = false
            },
            {
                id=-1,
                title="No title",
                win_id=-1,
                active = false
            },
            {
                id=-1,
                title="No title",
                win_id=-1,
                active = false
            },
        },
        child_windows={},
        win_id = -1,
        style = {
            max_height = 0,
            max_width = 0,
            width = 0,
            height = 0
        }
    }
end


local  M = {
    windows={
        left_window = create_win_props(),
        center_window = create_win_props(),
        right_window=create_win_props(),
        bottom_window=create_win_props()
    },
    navigator={
        current_parent_win = -1
    }
}


local function HELP_FUNCTION()

    print(vim.inspect(M))

end
    vim.api.nvim_create_user_command("HelpPrint",HELP_FUNCTION,{})


local function remove_buffer_from_center(list, target_id)
    for i, item in ipairs(list) do
        if item.id == target_id then
            table.remove(list, i)
            print("Removed")
            return true  -- Item found and removed
        end
    end
    return false  -- Item not found
end


local function create_new_buffer_on_buffer_slot(slots,index)
    local buffer_slot = slots[index]
    local new_buf = vim.api.nvim_create_buf(false,false)
    vim.api.nvim_win_set_buf(buffer_slot.win_id,new_buf)
    vim.api.nvim_buf_delete(buffer_slot.id,{force=true})

    buffer_slot.id = new_buf

    return new_buf

end

local function open_file_in_window_buffer(window,buffer,path)
    print(".. " .. window .. "  " .. buffer)
    print(path)
    vim.api.nvim_win_set_buf(window,buffer)
    vim.api.nvim_buf_call(buffer,function()vim.cmd('edit' .. path) end)
end


local function init_file_explorer(left_window_id)
    vim.api.nvim_set_current_win(left_window_id)
    local tree = require("nvim-tree.api")
    tree.tree.open({
        current_window=true
    })
end



local function open_file_center_view(node_absolute_path,new_buff)
    local center_buf = -1
    if new_buff then
            center_buf = vim.api.nvim_create_buf(false, false)
            table.insert(M.windows.center_window.buffers,buffer_props(center_buf))
            M.windows.center_window.current_buffer_index = #M.windows.center_window.buffers
    else
        local new_buf = create_new_buffer_on_buffer_slot(M.windows.center_window.buffers,M.windows.center_window.current_buffer_index)
        open_file_in_window_buffer(M.windows.center_window.win_id,new_buf,node_absolute_path)
    end
end

local function next_buffer_center_view()
    if #M.windows.center_window.buffers == M.windows.center_window.current_buffer_index then
        M.windows.center_window.current_buffer_index = 1
    else
        M.windows.center_window.current_buffer_index = M.windows.center_window.current_buffer_index + 1
    end
    vim.api.nvim_win_set_buf(M.windows.center_window.win_id,M.windows.center_window.buffers[M.windows.center_window.current_buffer_index].id)
end



-- -- Function to open references in a specific window
-- local function open_references_in_window(target_winid)
--     -- Store current window
--     local current_win = vim.api.nvim_get_current_win()
    
--     -- Focus target window
--     vim.api.nvim_set_current_win(M.right_window.win_id)
    
--     -- Get references (will use location list for this window)
--     vim.lsp.buf.references()
    
--     -- Optionally return to original window
--     -- vim.api.nvim_set_current_win(current_win)
-- end




local function create_toggle_callbacks(win_id,win_props,orientation)

    return function()
        if orientation == HEIGHT_ORIENTATION then
            if(win_props.height == 0) then
                win_props.height = win_props.max_height
            else
                win_props.height = 0
            end
            vim.api.nvim_win_set_height(win_id, win_props.height)
        else
            if(win_props.width == 0) then
                win_props.width = win_props.max_width
            else
                win_props.width = 0
            end
            vim.api.nvim_win_set_width(win_id, win_props.width)  -- Fixed typo
        end
    end
end


local function init_window(width)
    local left_window = vim.api.nvim_get_current_win()


    local bottom_width = math.floor(vim.o.columns * 1)
    local bottom_height = math.floor(vim.o.lines * 0.2)
    local bottom_buf = vim.api.nvim_create_buf(false, false)
    local bottom_win = vim.api.nvim_open_win(bottom_buf, true, {
        split = "below",  -- Opens to the right
        vertical = true,   -- Vertical split
        width = bottom_width,
        height = bottom_height
    })

    vim.api.nvim_set_current_win(left_window)

    local center_width = math.floor(vim.o.columns * 0.85)
    local center_buf = vim.api.nvim_create_buf(false, false)
    local center_win = vim.api.nvim_open_win(center_buf, true, {
        split = "right",  -- Opens to the right
        vertical = true,   -- Vertical split
        width = center_width
    })

    local right_width =math.floor( vim.o.columns * 0.2)
    local right_buf = vim.api.nvim_create_buf(false, false)
    local right_win = vim.api.nvim_open_win(right_buf, true, {
        split = "right",  -- Opens to the right
        vertical = true,   -- Vertical split
        width = right_width
    })

    M.windows.left_window.win_id = left_window
    M.windows.right_window.win_id = right_win
    M.windows.center_window.win_id = center_win
    M.windows.bottom_window.win_id = bottom_win

    M.windows.bottom_window.style.max_height = bottom_height
    M.windows.bottom_window.style.height = bottom_height

    M.windows.right_window.style.max_width = right_width
    M.windows.right_window.style.width = right_width

    M.windows.left_window.style.max_width = vim.api.nvim_win_get_width(left_window)
    M.windows.left_window.style.width = vim.api.nvim_win_get_width(left_window)

    M.windows.center_window.buffers[1].id = center_buf
    M.windows.center_window.buffers[1].title = "main"
    M.windows.center_window.buffers[1].win_id = center_win
    M.windows.center_window.current_buffer_index = 1


        -- Override the q keymap (not the command)
        ---Add logic that buffers can be removed
    vim.keymap.set('n', '<leader>r', function()
        local current_win = vim.api.nvim_get_current_win()
          if current_win == M.windows.left_window.win_id 
            or current_win == M.windows.center_window.win_id
            or current_win == M.windows.right_window.win_id
            or current_win == M.windows.bottom_window.win_id then


                if current_win == M.windows.center_window.win_id then
                    local buf_id = vim.api.nvim_win_get_buf(current_win)
                    if(buf_id ~= M.windows.center_window.buffers[1].id) then
                        vim.api.nvim_win_set_buf(M.windows.center_window.win_id,M.windows.center_window.buffers[1].id)
                        vim.api.nvim_buf_delete(buf_id,{force = true})
                        remove_buffer_from_center(M.windows.center_window.buffers,buf_id)
                    else
                        vim.api.nvim_buf_delete(buf_id,{force = true})
                        remove_buffer_from_center(M.windows.center_window.buffers,buf_id)
                        local center_buf = vim.api.nvim_create_buf(false, false)
                        M.windows.center_window.buffers[1] = buffer_props(center_buf,"main",center_win)

                    end
                end

                print("Cant delete " .. current_win)
                return
        end
        vim.cmd("q")
    end)


    -- vim.api.nvim_create_user_command("TestToggle",create_toggle_callbacks(bottom_win,M.bottom_window.style,HEIGHT_ORIENTATION),{})
    -- vim.api.nvim_create_user_command("TestToggle1",create_toggle_callbacks(right_win,M.right_window.style,WIDTH_ORIENTATION),{})
    vim.api.nvim_create_user_command("TestToggle2",next_buffer_center_view,{})



    --   vim.api.nvim_create_user_command("TestToggle4",function() 
    --     local must = require("nvim-tree.api")
    --     print(vim.inspect(must.node.open.replace_tree_buffer))

    --     must.tree.open({
    --         current_window=true
    --     })

    --   end
    --     ,{})

end


local function window_listener_setup()

    vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
        local current_win = vim.api.nvim_get_current_win()

       if current_win == M.windows.left_window.win_id 
            or current_win == M.windows.center_window.win_id
            or current_win == M.windows.right_window.win_id
            or current_win == M.windows.bottom_window.win_id then

                M.navigator.current_parent_win = current_win
        end
    end
})


-- Listen for new windows
vim.api.nvim_create_autocmd("WinNew", {
    callback = function()
        local new_win = vim.api.nvim_get_current_win()
        
        if(M.navigator.current_parent_win ~= M.windows.center_window.win_id)then
            vim.api.nvim_win_close(new_win,true)
            return
        end
        M.windows.center_window.child_windows[new_win] = child_win_props()
        print("New window created! ID: " .. new_win)
    end
})
end


M.init_window= init_window
M.init_file_explorer = init_file_explorer
M.window_listener_setup = window_listener_setup
M.open_file_center_buffer=open_file_center_view

return M