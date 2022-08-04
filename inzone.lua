--[[
    Created by Sic
    -- Thanks to the lua peeps, SpecialEd, kaen01, dannuic, knightly, aquietone, brainiac and all the others
--]]

local mq = require 'mq'
require 'ImGui'
require('lib.sic.utilfunc')

local inzonedisplaymsg = '\ao[\agInZoneDisplay\ao]\ag::\aw'

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true

-- Do you have a flag?

-- ImGui main function for rendering the UI window
local function inZoneDisplay()
    openGUI, shouldDrawGUI = ImGui.Begin('##InZone', openGUI, getFlagForLockedState())
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
        locked = false
    end

    if cmd == 'lock' then
        printf('%s \agLocked!', inzonedisplaymsg)
       locked = true
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