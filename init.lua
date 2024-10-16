--[[
    Created by Sic
    -- Thanks to the lua peeps, SpecialEd, kaen01, dannuic, knightly, aquietone, brainiac and all the others
--]]

local mq = require 'mq'
require 'ImGui'
--require('lib.sic.utilfunc')

local inzonedisplaymsg = '\ao[\agInZoneDisplay\ao]\ag::\aw'

--[[ TODO:: Fix git to use the library
    Created by Sic
    -- Thanks to the lua peeps, SpecialEd, kaen01, dannuic, knightly, aquietone, brainiac and all the others


    This will act as a little include library for reused functions
--]]

Locked = true
Anon = false

-- Colors w/ full alpha
Color_green = { 0, 1, 0, 1 }
Color_red = '1, 0, 0, 1'
Color_blue = '0, 0, 1, 1'

function Color_Text(rgba_t, text)
    local t = { unpack(rgba_t) }
    table.insert(t, #t+1, text)
    print(t)
    return unpack(t)
end

function printf(s,...)
    return print(string.format(s,...))
end

function IsAnyoneInvis()
    local groupsize = mq.TLO.Me.GroupSize()
    if groupsize ~= nil and groupsize > 0 then
        for i = 0, mq.TLO.Me.GroupSize() do
            if not mq.TLO.Group.Member(i).OtherZone() and mq.TLO.Group.Member(i).Invis() then
                return true
            end
        end
    end
    
    return mq.TLO.Me.Invis()
end

-- If we "unlock" the window we want to be able to move it and resize it
-- If we "lock" the window, we don't want to be able to click it, resize it, move it, etc.
-- Do you have a flag?!
function ImGuiButtonFlagsetFlagForLockedState()
    if Locked then
        return bit32.bor(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoBackground, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoInputs)
    elseif not Locked then
        return bit32.bor(ImGuiWindowFlags.NoTitleBar)
    end
end

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true

-- Do you have a flag?

-- ImGui main function for rendering the UI window
local function inZoneDisplay()
    openGUI, shouldDrawGUI = ImGui.Begin('##InZone', openGUI, ImGuiButtonFlagsetFlagForLockedState())
    if shouldDrawGUI then
        local macroname = mq.TLO.Macro.Name()
        local macrooutput = string.format("Mac: %s", macroname)
        local inzone = mq.TLO.SpawnCount('PC')()
        local output = string.format("PCs: %i", inzone)
        -- R, G, B, Alpha
        if macroname ~= nil then 
            ImGui.TextColored(0.05 , 0.95 , 0.95, 1, macrooutput)
        end
        ImGui.TextColored(0.05 , 0.95 , 0.95, 1, output)
    end
    ImGui.End()
end

mq.imgui.init('inZoneDisplay', inZoneDisplay)

local function help()
    printf('%s \agInvisDisplay options include:', inzonedisplaymsg)
    printf('%s \aounlock \ar---> \ag unlocks the window so you can move, size, and place it.', inzonedisplaymsg)
    printf('%s \aolock \ar---> \ag locks the window, making it click through, transparent, and immovable.', inzonedisplaymsg)
end

local function do_invisdisplay(cmd, cmd2)
    if cmd == 'unlock' then
        printf('%s \agUnlocked!', inzonedisplaymsg)
        Locked = false
    end

    if cmd == 'lock' then
        printf('%s \agLocked!', inzonedisplaymsg)
        Locked = true
    end
end

local function bind_invisdisplay(cmd, cmd2)
    if cmd == nil or cmd == 'help' then 
        help()
        return
    end

    do_invisdisplay(cmd, cmd2)
end

local function setup()
    -- make the bind
    mq.bind('/inzonedisplay', bind_invisdisplay)
    printf('%s \aoby \agSic', inzonedisplaymsg)
    printf('%s Please \ar\"/inzonedisplay help\"\ax for a options.', inzonedisplaymsg)
end

local function main()
    while true do
        mq.delay(300)
    end
end

-- set it the bind and such
setup()
-- run the main loop
main()