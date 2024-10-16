
-- Mission_FinalFugue
-- Version 1.1
--
-- 1. Get Task 
--      - say "smaller" to Shalowain in Laurion Inn
-- 2. Zone into Pal'Lomen
-- 3. Run this script
---------------------------

local mq = require('mq')
local lip = require('lib.LIP')

---------------------------
--- CHANGE these per your desires
local DebugOutput = false
local main_zone = 'pallomen'
local quest_zone = 'pallomen_mission'

local settings = {
    general = {
        GroupMessage = "dannet", -- or "bc"
        MoveGroupToQuestZone = false,
        KillArchers = false,
        UseBandoliers = true,
        StunBandolierName = "stun",
        RegularBandolierName = "standard",
        OpenChest = false
    }
}

local config_path = ''

local function Log(output, ...)
    printf('[\agFinalFugue\aw] '..output, ...)
end

local function LogDebug(output, ...)
    if (DebugOutput == false) then return end
    printf(output, ...)
end

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

local function load_settings()
    local config_dir = mq.configDir:gsub('\\', '/') .. '/'
    local config_file = string.format('mission_finalfugue_%s.ini', mq.TLO.Me.CleanName())
    config_path = config_dir .. config_file
    if (file_exists(config_path) == false) then
        lip.save(config_path, settings)
   else
        settings = lip.load(config_path)

        -- Version updates
        if (settings.general.UseBandoliers == nil) then
            settings.general.UseBandoliers = true
            lip.save(config_path, settings)
        end
   end
 end

 load_settings()

 if (settings.general.GroupMessage == 'dannet') then
    Log('\aw Group Chat: \ayDanNet\aw.')
 elseif (settings.general.GroupMessage == 'bc') then
    Log('\aw Group Chat: \ayBC\aw.')
 else
    Log("Unknown or invalid group command.  Must be either 'dannet' or 'bc'. Ending macro. \ar%s", settings.general.GroupMessage)
    os.exit()
 end

 Log('\aw Killing Archers: \ay%s', settings.general.KillArchers)
 Log('\aw Use Bandoliers: \ay%s', settings.general.UseBandoliers)
 if (settings.general.UseBandoliers) then
    Log('\aw Stun Bandolier: \ay%s', settings.general.StunBandolierName)
    Log('\aw Reg  Bandolier: \ay%s', settings.general.RegularBandolierName)
 end
 Log('\aw Open Chest: \ay%s', settings.general.OpenChest)

 ---------------------------

local task = mq.TLO.Task('Final Fugue')

if (task() == nil) then Log('Do not have the quest. Fix that.') return end

local function send_group_message(command, ...)

    local full_command = string.format(command, ...)
    if (settings.general.GroupMessage == 'dannet') then
        full_command = string.format('/dgga %s', full_command)
    else
        full_command = string.format('/bcga /%s', full_command)
    end

    mq.cmd(full_command)
end

local function is_up(spawn_name)
    return mq.TLO.Spawn(spawn_name).ID() > 0
end

local function TravelTo(zoneName, whole_group)
    if mq.TLO.Zone.ShortName() ~= zoneName then
        Log('Traveling to %s', zoneName)
        if (whole_group) then
            send_group_message('/travelto %s', zoneName)
        else
            mq.cmdf('/travelto %s', zoneName)
        end
        --traveling, please wait--
        while mq.TLO.Navigation.Active do
            mq.delay(50)
        end
        mq.delay(50)
        while mq.TLO.Zone.ShortName() ~= zoneName do
            mq.delay(500)
        end
    end
end

if (mq.TLO.Zone.ShortName() == main_zone) then
    if (settings.general.MoveGroupToQuestZone) then
        TravelTo(quest_zone, true)
    else
        Log("\ag Move to quest zone (Pal'Lomen door) then re-run script")
        return
    end
end

if (mq.TLO.Zone.ShortName() ~= quest_zone) then Log('Not in correct zone. Fix that and start again.') return end

local steps = {
    start=1,
    openChest=2,
}

local function MoveTo(spawn, distance)
    if (mq.TLO.SpawnCount(spawn)() <= 0) then return false end

    if (distance == nil) then distance = 5 end

    if (mq.TLO.Spawn(spawn).Distance() < distance) then return true end

    mq.cmdf('/squelch /nav spawn "%s" npc |dist=%s', spawn, distance)
    while mq.TLO.Nav.Active() do mq.delay(1) end
    mq.delay(500)
    return true
end

local function MoveToLoc(locXyz)
    mq.cmdf('/squelch /nav loc %s', locXyz)
    while mq.TLO.Nav.Active() do mq.delay(1) end
    mq.delay(500)
    return true
end

local function MoveToId(id)
    mq.cmdf('/squelch /nav id %s', id)
    while mq.TLO.Nav.Active() do mq.delay(1) end
    mq.delay(500)
    return true
end

local function MoveToAndAttack(spawn)
    if MoveTo(spawn) == false then return false end
    mq.cmdf('/squelch /target %s', spawn)
    mq.delay(250)
    mq.cmd('/attack on')
    return true
end

local function MoveToAndTarget(spawn)
    if MoveTo(spawn) == false then return false end
    mq.cmdf('/squelch /target %s', spawn)
    mq.delay(250)
    return true
end

local function MoveToAndTargetId(id)
    if MoveToId(id) == false then return false end
    mq.cmdf('/squelch /target id %s', id)
    mq.delay(250)
    return true
end

local function MoveToAndAct(spawn,cmd)
    if MoveToAndTarget(spawn) == false then return false end
    mq.cmd(cmd)
    mq.cmd('/squelch /target clear')
    return true
end

local function CorpseTargetCheck()
    if (mq.TLO.Target.Type() == "Corpse") then
        mq.delay(500)
    end
end

local function MoveToAndHail(spawn) return MoveToAndAct(spawn, '/hail') end
local function MoveToAndSay(spawn,say) return MoveToAndAct(spawn, string.format('/say %s', say)) end
local function MoveToAndOpen(spawn) return MoveToAndAct(spawn, '/open') end

local function KillAllBaddiesIfUp(spawn, distance)
    local logged = false
    local mob_found = false
    while(true) do
        local spawn_search = spawn
        if (distance ~= nil) then
            spawn_search = string.format('%s radius %s', spawn, distance)
        end

        if (mq.TLO.SpawnCount(spawn_search)() == 0) then
            LogDebug('No \at%s\ay up (%s)', spawn, spawn_search)
            return mob_found
        end

        mob_found = true

        if (logged == false) then
            Log('Killing \at%s', spawn)
            logged = true
        end

        if (MoveToAndAttack(spawn) == false) then LogDebug('Move/Attack for (%s) failed', spawn) return end
        CorpseTargetCheck()
    end
end

local function KillAllBaddiesIfUpAndAnotherDown(spawn, previous_spawn, distance)
    if (mq.TLO.SpawnCount(previous_spawn)() > 0) then
        LogDebug('Not killing \ay%s\aw as \ag%s\aw is up', spawn, previous_spawn)
        return false
    end
    return KillAllBaddiesIfUp(spawn, distance)
end

local function DoStep(step, action)
    local objective = task.Objective(step)
    if (objective.Status() == "Done") then
        Log('Step %s is done.', step)
        return true
    elseif (objective.Status() == nil) then
        Log('Step %s hasnt been unlocked. Jumping back to top.', step)
        mq.delay(1000)
        return false
    end

    Log('Executing step %s.', step)
    local result = action(objective)
    mq.delay(500)
    return result
end

local function wave1()
    local target = nil
    if (mq.TLO.Spawn('A Rallosian hex').ID() > 0) then
        target = 'A Rallosian hex'
    elseif (mq.TLO.Spawn('A Rallosian warlock').ID() > 0) then
        target = 'A Rallosian warlock'
    else
        if (KillAllBaddiesIfUp("A rallosian soldier", 60) == true) then
            return
        end
    end

    if (target == nil) then return end

    Log('See \ay%s.\aw.  Waiting for it to get in range.', target)

    while(true) do
        local spawn = mq.TLO.Spawn(target)
        if (spawn.ID() <= 0) then return end
        if spawn.Distance() <= 120 then
            KillAllBaddiesIfUp(target)
            return
        else
            mq.delay(100)
        end
    end
end

local function wave2()
    KillAllBaddiesIfUp("handler", 80)
    KillAllBaddiesIfUp("boar", 80)
    KillAllBaddiesIfUp("wraith", 80)
end

local function wave3()
    local mob_name = 'A Rallosian hunter'

    local spawn = mq.TLO.Spawn('Shalow')
    if (spawn.ID() == 0) then return end
    if (spawn.Y() < -400 or spawn.Y() > -100) then return end

    MoveToLoc('-30 -293 -35')
    Log('\ay Ready for hunters.  Waiting 5 seconds then engaging (%s)', spawn.Y())
    mq.delay(5000)

    KillAllBaddiesIfUp(mob_name, 400)
end

local function kill_archers()
    if (settings.general.KillArchers == false) then return end
    if (mq.TLO.SpawnCount('archer')() == 0) then return end

    Log('\ay Going to kill archers...')
    send_group_message('/target id %s', mq.TLO.Me.ID())
    KillAllBaddiesIfUp('archer')
end

local function swap_bandolier(bandolier_name)
    if (settings.general.UseBandoliers == false) then return end

    send_group_message('/bandolier activate %s', bandolier_name)
end

local captain_name = 'Captain Kar the Unmovable'
local function kill_kar()
    local in_stun_mode = false
    while(true) do
        local spawn = mq.TLO.Spawn('npc '..captain_name)
        if (spawn == nil or spawn.ID() == 0) then Log('Captain Kar \arDead\aw Or mission reset')
            return
        end

        if (mq.TLO.Target.Name() ~= captain_name) then
            mq.cmd('/squelch /target Captain Kar')
            mq.cmd('/attack on')
        end

        -- We occasionally get stun/kicked and need to return
        if (spawn.Distance() > 15) then MoveTo(captain_name) end

        if (spawn.Level() >= 125) then
            if (in_stun_mode) then
                Log('\ag Resume Attack \aw')
                swap_bandolier(settings.general.RegularBandolierName)
                in_stun_mode = false
            end
        elseif (in_stun_mode == false) then
            kill_archers()

            Log('\ay Stun! \aw')
            swap_bandolier(settings.general.StunBandolierName)
            in_stun_mode = true
        end

        mq.delay(250)
    end
end

local function MoveToShalowain()
    if (is_up('Shalowain') == true and mq.TLO.Spawn('Shalowain').Distance() > 50) then
        LogDebug('\ay Catching up to Shalowain and friends.')
        MoveTo('Shalowain')
    end
end

local function get_stage()
    if (mq.TLO.Me.XTarget(1).ID() and mq.TLO.Me.XTarget(1).Name() == captain_name) then
        return 'boss_fight'
    end

    -- if (mq.TLO.Spawn('Elmara').ID() == 0) then
    if (is_up('Elmara') == false) then
        return 'boss_fight'
    end

    return 'trash'
end

local function action_start(step)
    -- Not idempotent, but not really a problem.
    MoveToAndSay('Shalowain', 'they come')

    local stage = ''

    while step.Status() ~= "Done" do
        wave1()
        wave2()
        wave3()

        MoveToShalowain()

        KillAllBaddiesIfUp("Darga Smasher", 50)
        KillAllBaddiesIfUpAndAnotherDown("Margator the Slow", "Darga Smasher", 50)
        KillAllBaddiesIfUpAndAnotherDown("Firethorn", "Margator the Slow", 50)
        KillAllBaddiesIfUpAndAnotherDown("Yarith Wardbreaker", "Firethorn", 50)

        stage = get_stage()
        if (stage == 'boss_fight') then
            Log('Engaging \agCaptain Kar')
            kill_kar()
        end

        MoveToShalowain()

        mq.delay(500)

        if (mq.TLO.Zone.ShortName() ~= quest_zone) then
            Log('\ar Exited zone.\aw Ending macro.')
            os.exit()
        end
    end
end

local function action_openChest(step)
    MoveToAndOpen('a war chest')
end

local function event_failed()
    mq.cmd('/beep')
    Log('\ar Event Failed.\aw Aborting');
    os.exit()
end

mq.event('event_failed', "#*#Some of the Rallosian army were left to their own devices.#*#", event_failed)

::restart::
if (DoStep(steps.start, action_start) == false) then goto restart end
if (settings.general.OpenChest) then
    printf('\at Opening Chest')
    if (DoStep(steps.openChest, action_openChest) == false) then goto restart end
end

Log('\ar Done.')
