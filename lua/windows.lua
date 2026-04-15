


local HEIGHT_ORIENTATION = 1
local WIDTH_ORIENTATION = 0

local BUF_TYPE_NO_FILE=1
local BUF_TYPE_FILE=2

-- Create your own namespace
local my_ns = vim.api.nvim_create_namespace("my_plugin_name")


local function buffer_props(id,title,win_id,file_path,buf_type)
    return {
        id=id,
        title=title,
        file_path=file_path,
        win_id=win_id,
        buf_type=buf_type
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
            buffer_props(-1,"/",-1,"nil",BUF_TYPE_NO_FILE),
            buffer_props(-1,"/",-1,"nil",BUF_TYPE_NO_FILE),
            buffer_props(-1,"/",-1,"nil",BUF_TYPE_NO_FILE),
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



local function create_new_buffer_on_buffer_slot(slots,index,absolute_path,filename,type)
    local buffer_slot = slots[index]
    local new_buf = vim.api.nvim_create_buf(false,false)
    local win_id = buffer_slot.win_id
    vim.api.nvim_win_set_buf(win_id,new_buf)

    if(vim.api.nvim_buf_is_valid(buffer_slot.id))then
            vim.api.nvim_buf_delete(buffer_slot.id,{force=true})
    end
    slots[index] = buffer_props(new_buf,filename,win_id,absolute_path,type)
    return new_buf

end

local function open_file_in_window_buffer(window,buffer,path)
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


local function open_file_center_view(node_absolute_path,new_buff,filename)
    if new_buff then
        print(#M.windows.center_window.buffers .. "   " .. M.windows.center_window.current_buffer_index)
            if(#M.windows.center_window.buffers == M.windows.center_window.current_buffer_index )then
                M.windows.center_window.current_buffer_index = 1
            else
                M.windows.center_window.current_buffer_index = M.windows.center_window.current_buffer_index + 1
            end
            M.windows.center_window.buffers[M.windows.center_window.current_buffer_index].win_id = M.windows.center_window.win_id
    end
     local new_buf = create_new_buffer_on_buffer_slot(M.windows.center_window.buffers,M.windows.center_window.current_buffer_index,node_absolute_path,filename,BUF_TYPE_FILE)
    open_file_in_window_buffer(M.windows.center_window.win_id,new_buf,node_absolute_path)
    vim.api.nvim_set_current_win(M.windows.center_window.win_id)
end



local function next_buffer_center_view()
    if #M.windows.center_window.buffers == M.windows.center_window.current_buffer_index then
        M.windows.center_window.current_buffer_index = 1
    else
        M.windows.center_window.current_buffer_index = M.windows.center_window.current_buffer_index + 1

        while M.windows.center_window.buffers[M.windows.center_window.current_buffer_index ].id == -1 do
                if #M.windows.center_window.buffers == M.windows.center_window.current_buffer_index then
                    M.windows.center_window.current_buffer_index = 1
                else
                    M.windows.center_window.current_buffer_index = M.windows.center_window.current_buffer_index + 1
                end
        end
    end
    vim.api.nvim_win_set_buf(M.windows.center_window.win_id,M.windows.center_window.buffers[M.windows.center_window.current_buffer_index].id)
end

----------------------------------------------------------------------------------------------------------------
local function on_remove_on_center_window()
    local index = M.windows.center_window.current_buffer_index
    local buffer_slot = M.windows.center_window.buffers[index]
    local temp_buf = vim.api.nvim_create_buf(false,false)
    local buf_to_delete = buffer_slot.id
    vim.api.nvim_win_set_buf(M.windows.center_window.win_id,temp_buf)
    print("Deleting buffer" .. buf_to_delete)
    vim.api.nvim_buf_delete(buf_to_delete,{force = true})
    M.windows.center_window.buffers[index] = buffer_props(temp_buf,"/",M.windows.center_window.win_id,"nil",BUF_TYPE_NO_FILE)

    local find = true
    local cycle_repeat = index
    while find do
        index = index + 1
        if index > #M.windows.center_window.buffers then
            index = 1
        end
        if M.windows.center_window.buffers[index].buf_type == BUF_TYPE_NO_FILE then
            if cycle_repeat == index then
                find = false
            end
        else
                vim.api.nvim_win_set_buf(M.windows.center_window.win_id,M.windows.center_window.buffers[index].id)
                M.windows.center_window.current_buffer_index = index
                find = false
        end
    end
end
----------------------------------------------------------------------------------------------------------------

local function display_list_of_buffers_center()

    vim.api.nvim_set_current_win(M.windows.center_window.win_id)
   -- Get the target window's position and size
    local win_config = vim.api.nvim_win_get_config(M.windows.center_window.win_id)
    local win_width = win_config.width
    -- Calculate center position relative to target window
    local col = (math.floor(win_width / 2)-15)
    -- Create buffer for float window
    local buf = vim.api.nvim_create_buf(false, true)


    local float_opts = {
        relative = 'win',  -- Can also use 'win' to be relative to target_win
        width = 30,
        height = #M.windows.center_window.buffers + 1,
        row = 0,
        col = col,
        border = 'single',  -- 'none', 'single', 'double', 'rounded', 'solid'
        style = 'minimal'
    }
    
    -- Create the floating window
    local float_win = vim.api.nvim_open_win(buf, true, float_opts)
    vim.api.nvim_win_set_option(float_win, 'winhighlight', 'NormalFloat:N,FloatBorder:Border')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    local lines = {}
    for index, buffer in ipairs(M.windows.center_window.buffers) do

        table.insert(lines, string.format("%d: %s", index, buffer.title))

        vim.api.nvim_buf_set_keymap(buf, 'n', tostring(index), '', {
            callback = function() 
                if buffer.id ~= -1 then
                    vim.api.nvim_win_set_buf(M.windows.center_window.win_id,buffer.id)
                    M.windows.center_window.current_buffer_index = index
                end
            end,
            noremap = true,
            silent = true,
        })
    end

    vim.api.nvim_buf_set_keymap(buf, 'n', "<leader>r", '', {
        callback = function()
            local cursor =  vim.api.nvim_win_get_cursor(float_win)
            local index =cursor[1]
            local buffer = M.windows.center_window.buffers[index]
            if buffer.id ~= -1 then
                on_remove_on_center_window()
                vim.api.nvim_buf_set_option(buf, 'modifiable', true)
                vim.api.nvim_buf_set_lines(buf, index-1, index, false, {string.format("%d: %s",index,'/')})
                vim.api.nvim_buf_set_option(buf, 'modifiable', false)
            end
        end,
        noremap = true,
        silent = true,
    })

-- Set the lines in buffer
vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
-- Make it read-only (cannot write)
vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end
----------------------------------------------------------------------------------------------------------------

vim.api.nvim_create_user_command("DisplayBuffers",display_list_of_buffers_center,{})





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
                        on_remove_on_center_window()
                end
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