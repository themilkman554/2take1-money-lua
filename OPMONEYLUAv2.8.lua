---@diagnostic disable: undefined-global, lowercase-global, undefined-field
local natives <const> = require("lib.natives2845")
local gtascriptver = 1.68
local scriptver = 2.8
do 
    if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_SCRIPT_VARS) and not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_NATIVES) then
        menu.notify("TURN ON TRUSTED LOCAL/GLOBAL AND NATIVES TO USE SCRIPT", "", 5, 0xFF00FFFF)
        return menu.exit()
    end
	online_v = tonumber(natives.NETWORK.GET_ONLINE_VERSION())
	if online_v ~= gtascriptver then
	menu.notify("Outdated Lua, please download the new version on Discord. Game Version is " .. online_v .. " Script Version is for 1.68", "", 5, 0xFF00FFFF)
	return menu.exit()
	end
    if not utils.file_exists(utils.get_appdata_path("PopstarDevs", "2Take1Menu") .. "\\scripts\\".."lib\\natives2845.lua") then -- check if natives is installed
        menu.notify("Download the natives from scripts > install scripts > natives2845 to use this script", "",  5, 0xFF00FFFF)
        return menu.exit()
    end
end

local menuRoot <const> = menu.add_feature("OP Money Loop " .. scriptver, "parent", 0).id	
local transactions <const> = menu.add_feature("Limited Transactions", "parent", menuRoot).id	
local loopSettings <const> = menu.add_feature("Loop Settings", "parent", menuRoot).id	
local set_global_i <const> = script.set_global_i	
local recovery <const> = 4537212
local playerCharacter <const> = stats.stat_get_int(gameplay.get_hash_key("mpply_last_mp_char"), 0)	

local currentMoney = natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter)
local moneyEarned = 0
local moneyEarnedPerMinute = 0
local startTime = 0
local wait = false
local joaat <const> = gameplay.get_hash_key
local overlay
local displayTime
local displayEarned
local displayEarnedPerHour
local displayEarnedPerMin 
local displayEarnedPerSec

local function startTimer()
    startTime = os.time()
end

local function stopTimer()
    startTime = 0
end

local function getElapsedSeconds()
    if startTime ~= 0 then
        return os.time() - startTime
    else
        return 0
    end
end

local function addCommas(number)
    local numberString = tostring(number)
    local decimalIndex = string.find(numberString, "%.")
    if decimalIndex then
        numberString = string.sub(numberString, 1, decimalIndex - 1)
    end
    local reversedString = string.reverse(numberString)
    local formattedString = string.gsub(reversedString, "(%d%d%d)", "%1,")
    formattedString = string.reverse(formattedString)
    if string.sub(formattedString, 1, 1) == "," then
        formattedString = string.sub(formattedString, 2)
    end
    return formattedString
end

local function checkEarned(amount)
    if overlay.on then
        if natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter) > 2147483640 then
            menu.notify("Attempting to transfer all money to bank", "", 4, 0xFFEEEE00)
            wait = true
            local wallet = natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter)
            repeat
                wallet = natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter)
                natives.NETSHOPPING.NET_GAMESERVER_TRANSFER_WALLET_TO_BANK(playerCharacter, wallet)
                system.wait()
            until wallet == 0
            wait = false
            menu.notify("Continuing loop", "", 4, 0xFFEEEE00)
        end

        if natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter) - currentMoney == amount then
            moneyEarned = moneyEarned + amount
        end
        currentMoney = natives.MONEY.NETWORK_GET_VC_WALLET_BALANCE(playerCharacter)
    end
end 

local function amountPerHour(moneyEarned)
    if overlay.on then
        moneyEarnedPerMinute = moneyEarned / getElapsedSeconds() * 3600
    end
    return moneyEarnedPerMinute
end

local function amountPerMinute(moneyEarned)
    if overlay.on then
        moneyEarnedPerMinute = moneyEarned / getElapsedSeconds() * 60
    end
    return moneyEarnedPerMinute
end

local function amountPerSecond(moneyEarned)
    if overlay.on then
        moneyEarnedPerMinute = moneyEarned / getElapsedSeconds()
    end
    return moneyEarnedPerMinute
end

local function trigger_transaction(hash, amount)
    set_global_i(recovery + 1, 2147483646)
    set_global_i(recovery + 7, 2147483647)
    set_global_i(recovery + 6, 0)
    set_global_i(recovery + 5, 0)
    set_global_i(recovery + 3, hash)
    set_global_i(recovery + 2, amount)
    set_global_i(recovery, 2)
    checkEarned(amount)
end

local function draw_stats()
    if overlay.on then

        if displayTime.on then
            scriptdraw.draw_text("Seconds Elapsed: " .. getElapsedSeconds(), v2(0.55, 0.6), v2(0,0), 0.75, 0xFFFFFFFF, eDrawTextFlags.TEXTFLAG_SHADOW)
        end

        if displayEarned.on then
            scriptdraw.draw_text("Money Earned: $" .. addCommas(moneyEarned), v2(0.55, 0.5), v2(0,0), 0.75, 0xFFFFFFFF, eDrawTextFlags.TEXTFLAG_SHADOW)
        end

        if displayEarnedPerHour.on then
            scriptdraw.draw_text("Money/Hour: $" .. addCommas(amountPerHour(moneyEarned)), v2(0.55, 0.4), v2(0,0), 0.75, 0xFFFFFFFF, eDrawTextFlags.TEXTFLAG_SHADOW)
        end

        if displayEarnedPerMin.on then
            scriptdraw.draw_text("Money/Minute: $" .. addCommas(amountPerMinute(moneyEarned)), v2(0.55, 0.3), v2(0,0), 0.75, 0xFFFFFFFF, eDrawTextFlags.TEXTFLAG_SHADOW)
        end

        if displayEarnedPerSec.on then
            scriptdraw.draw_text("Money/Second: $" .. addCommas(amountPerSecond(moneyEarned)), v2(0.55, 0.2), v2(0,0), 0.75, 0xFFFFFFFF, eDrawTextFlags.TEXTFLAG_SHADOW)
        end

    end
    return HANDLER_CONTINUE
end

overlay = menu.add_feature("Enable Overlay", "toggle", loopSettings, draw_stats)

displayTime = menu.add_feature("Display Elapsed Time", "toggle", loopSettings)
displayEarned = menu.add_feature("Display Total Earned", "toggle", loopSettings)
displayEarnedPerHour = menu.add_feature("Display Earned Per Hour", "toggle", loopSettings)
displayEarnedPerMin = menu.add_feature("Display Earned Per Minute", "toggle", loopSettings)
displayEarnedPerSec = menu.add_feature("Display Earned Per Second", "toggle", loopSettings)

menu.add_feature("1 Million Loop #FF00EE00#[BEST]", "toggle", menuRoot, function(feat)
    if feat.on then
        startTimer()
    end

    while feat.on do

        if wait then
            repeat
                system.wait()
            until wait == false
        end

        trigger_transaction(0x615762F1, 1000000)
        system.wait()
    end

    moneyEarned = 0
    stopTimer()
end)

menu.add_feature("40m Loop #FF00EEEE#[SLOW]", "toggle", menuRoot, function(feat)
    if feat.on then
        startTimer()
    end

    while feat.on do
    trigger_transaction(joaat("SERVICE_EARN_BEND_JOB"), 15000000)
	trigger_transaction(joaat("SERVICE_EARN_GANGOPS_AWARD_MASTERMIND_3"), 7000000)
	trigger_transaction(joaat("SERVICE_EARN_JOB_BONUS"), 15000000)
	trigger_transaction(joaat("SERVICE_EARN_DAILY_OBJECTIVE_EVENT"), 1000000)
	trigger_transaction(joaat("SERVICE_EARN_FROM_BUSINESS_HUB_SELL"), 2000000)
        system.yield(20000)
    end

    moneyEarned = 0
    stopTimer()
end)

menu.add_feature("50K Loop", "toggle", menuRoot, function(feat)
    if feat.on then
        startTimer()
    end

    while feat.on do

        if wait then
            repeat
                system.wait()
            until wait == false
        end

    trigger_transaction(joaat("SERVICE_EARN_YOHAN_SOURCE_GOODS"), 50000)
        system.yield()
    end

    moneyEarned = 0
    stopTimer()
end)

menu.add_feature("5k Chips Loop", "toggle", menuRoot, function(feat)
    while feat.on do 
        set_global_i(1963515, 1)
        system.yield(3000)
    end
end)

menu.add_feature("Fake Money Loop", "toggle", menuRoot, function(feat)
    while feat.on do 
          amt = math.random(100000000, 300000000)
		  natives.HUD.CHANGE_FAKE_MP_CASH(0, amt)
        system.yield(0)
    end
end)

local Options = {
    {name = "15m JOB_BONUS", hash = joaat("SERVICE_EARN_JOB_BONUS"), amount = 15000000},
    {name = "15m BEND_JOB", hash = joaat("SERVICE_EARN_BEND_JOB"), amount = 15000000},
    {name = "15m GANGOPS_AWARD_MASTERMIND_4", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_MASTERMIND_4"), amount = 15000000},        
    {name = "15m JOB_BONUS_CRIMINAL_MASTERMIND", hash = joaat("SERVICE_EARN_JOB_BONUS_CRIMINAL_MASTERMIND"), amount = 15000000},  
    {name = "7m GANGOPS_AWARD_MASTERMIND_3", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_MASTERMIND_3"), amount = 7000000},
    {name = "3.6m CASINO_HEIST_FINALE", hash = joaat("SERVICE_EARN_CASINO_HEIST_FINALE"), amount = 3619000},
    {name = "3m AGENCY_STORY_FINALE", hash = joaat("SERVICE_EARN_AGENCY_STORY_FINALE"), amount = 3000000},
    {name = "3m GANGOPS_AWARD_MASTERMIND_2", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_MASTERMIND_2"), amount = 3000000},
    {name = "2.5m ISLAND_HEIST_FINALE", hash = joaat("SERVICE_EARN_ISLAND_HEIST_FINALE"), amount = 2550000},
    {name = "2.5m GANGOPS_FINALE", hash = joaat("SERVICE_EARN_GANGOPS_FINALE"), amount = 2550000},
    {name = "2m JOB_BONUS_HEIST_AWARD", hash = joaat("SERVICE_EARN_JOB_BONUS_HEIST_AWARD"), amount = 2000000},
    {name = "2m TUNER_ROBBERY_FINALE", hash = joaat("SERVICE_EARN_TUNER_ROBBERY_FINALE"), amount = 2000000},
    {name = "2m GANGOPS_AWARD_ORDER", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_ORDER"), amount = 2000000},
    {name = "2m FROM_BUSINESS_HUB_SELL", hash = joaat("SERVICE_EARN_FROM_BUSINESS_HUB_SELL"), amount = 2000000},
    {name = "1.5m GANGOPS_AWARD_LOYALTY_AWARD_4", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_LOYALTY_AWARD_4"), amount = 1500000},  
    {name = "1.2m BOSS_AGENCY", hash = joaat("SERVICE_EARN_BOSS_AGENCY"), amount = 1200000},
    {name = "1m DAILY_OBJECTIVES", hash = joaat("SERVICE_EARN_DAILY_OBJECTIVES"), amount = 1000000},
    {name = "1m MUSIC_STUDIO_SHORT_TRIP", hash = joaat("SERVICE_EARN_MUSIC_STUDIO_SHORT_TRIP"), amount = 1000000},
    {name = "1m DAILY_OBJECTIVE_EVENT", hash = joaat("SERVICE_EARN_DAILY_OBJECTIVE_EVENT"), amount = 1000000},
    {name = "1m JUGGALO_STORY_MISSION", hash = joaat("SERVICE_EARN_JUGGALO_STORY_MISSION"), amount = 1000000},
    {name = "700k GANGOPS_AWARD_LOYALTY_AWARD_3", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_LOYALTY_AWARD_3"), amount = 700000},   
    {name = "680k BETTING", hash = joaat("SERVICE_EARN_BETTING"), amount = 680000},
    {name = "620k FROM_VEHICLE_EXPORT", hash = joaat("SERVICE_EARN_FROM_VEHICLE_EXPORT"), amount = 620000},
    {name = "500k ISLAND_HEIST_AWARD_MIXING_IT_UP", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_MIXING_IT_UP"), amount = 500000},
    {name = "500k WINTER_22_AWARD_JUGGALO_STORY", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_JUGGALO_STORY"), amount = 500000},
    {name = "500k CASINO_AWARD_STRAIGHT_FLUSH", hash = joaat("SERVICE_EARN_CASINO_AWARD_STRAIGHT_FLUSH"), amount = 500000},
    {name = "400k ISLAND_HEIST_AWARD_PROFESSIONAL", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_PROFESSIONAL"), amount = 400000},
    {name = "400k ISLAND_HEIST_AWARD_CAT_BURGLAR", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_CAT_BURGLAR"), amount = 400000},
    {name = "400k ISLAND_HEIST_AWARD_ELITE_THIEF", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_ELITE_THIEF"), amount = 400000},
    {name = "400k ISLAND_HEIST_AWARD_THE_ISLAND_HEIST", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_THE_ISLAND_HEIST"), amount = 400000},
    {name = "350k CASINO_HEIST_AWARD_ELITE_THIEF", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_ELITE_THIEF"), amount = 350000},
    {name = "300k AMBIENT_JOB_BLAST", hash = joaat("SERVICE_EARN_AMBIENT_JOB_BLAST"), amount = 300000},
    {name = "300k PREMIUM_JOB", hash = joaat("SERVICE_EARN_PREMIUM_JOB"), amount = 300000},
    {name = "300k GANGOPS_AWARD_LOYALTY_AWARD_2", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_LOYALTY_AWARD_2"), amount = 300000},
    {name = "300k CASINO_HEIST_AWARD_ALL_ROUNDER", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_ALL_ROUNDER"), amount = 300000},
    {name = "300k ISLAND_HEIST_AWARD_PRO_THIEF", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_PRO_THIEF"), amount = 300000},
    {name = "300k YOHAN_SOURCE_GOODS", hash = joaat("SERVICE_EARN_YOHAN_SOURCE_GOODS"), amount = 300000},
    {name = "270k SMUGGLER_AGENCY", hash = joaat("SERVICE_EARN_SMUGGLER_AGENCY"), amount = 270000},
    {name = "250k FIXER_AWARD_AGENCY_STORY", hash = joaat("SERVICE_EARN_FIXER_AWARD_AGENCY_STORY"), amount = 250000},
    {name = "250k CASINO_HEIST_AWARD_PROFESSIONAL", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_PROFESSIONAL"), amount = 250000},
    {name = "200k GANGOPS_AWARD_SUPPORTING", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_SUPPORTING"), amount = 200000},
    {name = "200k COLLECTABLES_ACTION_FIGURES", hash = joaat("SERVICE_EARN_COLLECTABLES_ACTION_FIGURES"), amount = 200000},
    {name = "200k ISLAND_HEIST_AWARD_GOING_ALONE", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_GOING_ALONE"), amount = 200000},
    {name = "200k JOB_BONUS_FIRST_TIME_BONUS", hash = joaat("SERVICE_EARN_JOB_BONUS_FIRST_TIME_BONUS"), amount = 200000},
    {name = "200k GANGOPS_AWARD_FIRST_TIME_XM_SILO", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_FIRST_TIME_XM_SILO"), amount = 200000},
    {name = "200k DOOMSDAY_FINALE_BONUS", hash = joaat("SERVICE_EARN_DOOMSDAY_FINALE_BONUS"), amount = 200000},
    {name = "200k GANGOPS_AWARD_FIRST_TIME_XM_BASE", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_FIRST_TIME_XM_BASE"), amount = 200000},
    {name = "200k COLLECTABLE_COMPLETED_COLLECTION", hash = joaat("SERVICE_EARN_COLLECTABLE_COMPLETED_COLLECTION"), amount = 200000},
    {name = "200k ISLAND_HEIST_ELITE_CHALLENGE", hash = joaat("SERVICE_EARN_ISLAND_HEIST_ELITE_CHALLENGE"), amount = 200000},
    {name = "200k AMBIENT_JOB_CHECKPOINT_COLLECTION", hash = joaat("SERVICE_EARN_AMBIENT_JOB_CHECKPOINT_COLLECTION"), amount = 200000},
    {name = "200k GANGOPS_AWARD_FIRST_TIME_XM_SUBMARINE", hash = joaat("SERVICE_EARN_GANGOPS_AWARD_FIRST_TIME_XM_SUBMARINE"), amount = 200000},
    {name = "200k ISLAND_HEIST_AWARD_TEAM_WORK", hash = joaat("SERVICE_EARN_ISLAND_HEIST_AWARD_TEAM_WORK"), amount = 200000},
    {name = "200k CASINO_HEIST_ELITE_DIRECT", hash = joaat("SERVICE_EARN_CASINO_HEIST_ELITE_DIRECT"), amount = 200000},
    {name = "200k CASINO_HEIST_ELITE_STEALTH", hash = joaat("SERVICE_EARN_CASINO_HEIST_ELITE_STEALTH"), amount = 200000},
    {name = "200k AMBIENT_JOB_TIME_TRIAL", hash = joaat("SERVICE_EARN_AMBIENT_JOB_TIME_TRIAL"), amount = 200000},
    {name = "200k CASINO_HEIST_AWARD_UNDETECTED", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_UNDETECTED"), amount = 200000},
    {name = "200k CASINO_HEIST_ELITE_SUBTERFUGE", hash = joaat("SERVICE_EARN_CASINO_HEIST_ELITE_SUBTERFUGE"), amount = 200000},
    {name = "200k GANGOPS_ELITE_XM_SILO", hash = joaat("SERVICE_EARN_GANGOPS_ELITE_XM_SILO"), amount = 200000},
    {name = "190k VEHICLE_SALES", hash = joaat("SERVICE_EARN_VEHICLE_SALES"), amount = 190000},
    {name = "180k JOBS", hash = joaat("SERVICE_EARN_JOBS"), amount = 180000},
    {name = "165k AMBIENT_JOB_RC_TIME_TRIAL", hash = joaat("SERVICE_EARN_AMBIENT_JOB_RC_TIME_TRIAL"), amount = 165000},
    {name = "150k AMBIENT_JOB_BEAST", hash = joaat("SERVICE_EARN_AMBIENT_JOB_BEAST"), amount = 150000},
    {name = "150k CASINO_HEIST_AWARD_IN_PLAIN_SIGHT", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_IN_PLAIN_SIGHT"), amount = 150000},
    {name = "150k AMBIENT_JOB_SOURCE_RESEARCH", hash = joaat("SERVICE_EARN_AMBIENT_JOB_SOURCE_RESEARCH"), amount = 150000},
    {name = "150k GANGOPS_ELITE_XM_SUBMARINE", hash = joaat("SERVICE_EARN_GANGOPS_ELITE_XM_SUBMARINE"), amount = 150000},
    {name = "120k AMBIENT_JOB_KING", hash = joaat("SERVICE_EARN_AMBIENT_JOB_KING"), amount = 120000},
    {name = "120k AMBIENT_JOB_PENNED_IN", hash = joaat("SERVICE_EARN_AMBIENT_JOB_PENNED_IN"), amount = 120000},
    {name = "115k SIGHTSEEING_REWARD", hash = joaat("SERVICE_EARN_SIGHTSEEING_REWARD"), amount = 115000},
    {name = "100k CASINO_AWARD_HIGH_ROLLER_PLATINUM", hash = joaat("SERVICE_EARN_CASINO_AWARD_HIGH_ROLLER_PLATINUM"), amount = 100000},
    {name = "100k TUNER_AWARD_BOLINGBROKE_ASS", hash = joaat("SERVICE_EARN_TUNER_AWARD_BOLINGBROKE_ASS"), amount = 100000},
    {name = "100k CASINO_AWARD_FULL_HOUSE", hash = joaat("SERVICE_EARN_CASINO_AWARD_FULL_HOUSE"), amount = 100000},
    {name = "100k AGENCY_SECURITY_CONTRACT", hash = joaat("SERVICE_EARN_AGENCY_SECURITY_CONTRACT"), amount = 100000},
    {name = "100k DAILY_STASH_HOUSE_COMPLETED", hash = joaat("SERVICE_EARN_DAILY_STASH_HOUSE_COMPLETED"), amount = 100000},
    {name = "100k CASINO_AWARD_MISSION_SIX_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_SIX_FIRST_TIME"), amount = 100000},
    {name = "100k AMBIENT_JOB_CHALLENGES", hash = joaat("SERVICE_EARN_AMBIENT_JOB_CHALLENGES"), amount = 100000},
    {name = "100k AMBIENT_JOB_METAL_DETECTOR", hash = joaat("SERVICE_EARN_AMBIENT_JOB_METAL_DETECTOR"), amount = 100000},
    {name = "100k AMBIENT_JOB_HOT_PROPERTY", hash = joaat("SERVICE_EARN_AMBIENT_JOB_HOT_PROPERTY"), amount = 100000},
    {name = "100k AMBIENT_JOB_CLUBHOUSE_CONTRACT", hash = joaat("SERVICE_EARN_AMBIENT_JOB_CLUBHOUSE_CONTRACT"), amount = 100000},
    {name = "100k TUNER_AWARD_FLEECA_BANK", hash = joaat("SERVICE_EARN_TUNER_AWARD_FLEECA_BANK"), amount = 100000},
    {name = "100k AMBIENT_JOB_SMUGGLER_PLANE", hash = joaat("SERVICE_EARN_AMBIENT_JOB_SMUGGLER_PLANE"), amount = 100000},
    {name = "100k FIXER_AWARD_SHORT_TRIP", hash = joaat("SERVICE_EARN_FIXER_AWARD_SHORT_TRIP"), amount = 100000},
    {name = "100k AMBIENT_JOB_SMUGGLER_TRAIL", hash = joaat("SERVICE_EARN_AMBIENT_JOB_SMUGGLER_TRAIL"), amount = 100000},
    {name = "100k TUNER_AWARD_METH_JOB", hash = joaat("SERVICE_EARN_TUNER_AWARD_METH_JOB"), amount = 100000},
    {name = "100k CASINO_HEIST_AWARD_SMASH_N_GRAB", hash = joaat("SERVICE_EARN_CASINO_HEIST_AWARD_SMASH_N_GRAB"), amount = 100000},
    {name = "100k AGENCY_STORY_PREP", hash = joaat("SERVICE_EARN_AGENCY_STORY_PREP"), amount = 100000},
    {name = "100k WINTER_22_AWARD_DAILY_STASH", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_DAILY_STASH"), amount = 100000},
    {name = "100k JUGGALO_PHONE_MISSION", hash = joaat("SERVICE_EARN_JUGGALO_PHONE_MISSION"), amount = 100000},
    {name = "100k AMBIENT_JOB_GOLDEN_GUN", hash = joaat("SERVICE_EARN_AMBIENT_JOB_GOLDEN_GUN"), amount = 100000},
    {name = "100k AMBIENT_JOB_URBAN_WARFARE", hash = joaat("SERVICE_EARN_AMBIENT_JOB_URBAN_WARFARE"), amount = 100000},
    {name = "100k AGENCY_PAYPHONE_HIT", hash = joaat("SERVICE_EARN_AGENCY_PAYPHONE_HIT"), amount = 100000},
    {name = "100k TUNER_AWARD_FREIGHT_TRAIN", hash = joaat("SERVICE_EARN_TUNER_AWARD_FREIGHT_TRAIN"), amount = 100000},
    {name = "100k WINTER_22_AWARD_DEAD_DROP", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_DEAD_DROP"), amount = 100000},
    {name = "100k CLUBHOUSE_DUFFLE_BAG", hash = joaat("SERVICE_EARN_CLUBHOUSE_DUFFLE_BAG"), amount = 100000},
    {name = "100k WINTER_22_AWARD_RANDOM_EVENT", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_RANDOM_EVENT"), amount = 100000},
    {name = "100k TUNER_AWARD_MILITARY_CONVOY", hash = joaat("SERVICE_EARN_TUNER_AWARD_MILITARY_CONVOY"), amount = 100000},
    {name = "100k JUGGALO_STORY_MISSION_PARTICIPATION", hash = joaat("SERVICE_EARN_JUGGALO_STORY_MISSION_PARTICIPATION"), amount = 100000},
    {name = "100k AMBIENT_JOB_CRIME_SCENE", hash = joaat("SERVICE_EARN_AMBIENT_JOB_CRIME_SCENE"), amount = 100000},
    {name = "100k TUNER_AWARD_IAA_RAID", hash = joaat("SERVICE_EARN_TUNER_AWARD_IAA_RAID"), amount = 100000},
    {name = "100k ARENA_CAREER_TIER_PROGRESSION_4", hash = joaat("SERVICE_EARN_ARENA_CAREER_TIER_PROGRESSION_4"), amount = 100000},
    {name = "100k AUTO_SHOP_DELIVERY_AWARD", hash = joaat("SERVICE_EARN_AUTO_SHOP_DELIVERY_AWARD"), amount = 100000},
    {name = "100k CASINO_AWARD_TOP_PAIR", hash = joaat("SERVICE_EARN_CASINO_AWARD_TOP_PAIR"), amount = 100000},
    {name = "100k TUNER_AWARD_UNION_DEPOSITORY", hash = joaat("SERVICE_EARN_TUNER_AWARD_UNION_DEPOSITORY"), amount = 100000},
    {name = "100k AMBIENT_JOB_UNDERWATER_CARGO", hash = joaat("SERVICE_EARN_AMBIENT_JOB_UNDERWATER_CARGO"), amount = 100000},
    {name = "100k COLLECTABLE_ITEM", hash = joaat("SERVICE_EARN_COLLECTABLE_ITEM"), amount = 100000},
    {name = "100k WINTER_22_AWARD_ACID_LAB", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_ACID_LAB"), amount = 100000},
    {name = "100k AMBIENT_JOB_MAZE_BANK", hash = joaat("SERVICE_EARN_AMBIENT_JOB_MAZE_BANK"), amount = 100000},
    {name = "100k GANGOPS_ELITE_XM_BASE", hash = joaat("SERVICE_EARN_GANGOPS_ELITE_XM_BASE"), amount = 100000},
    {name = "100k WINTER_22_AWARD_TAXI", hash = joaat("SERVICE_EARN_WINTER_22_AWARD_TAXI"), amount = 100000},
    {name = "100k TUNER_DAILY_VEHICLE_BONUS", hash = joaat("SERVICE_EARN_TUNER_DAILY_VEHICLE_BONUS"), amount = 100000},
    {name = "100k TUNER_AWARD_BUNKER_RAID", hash = joaat("SERVICE_EARN_TUNER_AWARD_BUNKER_RAID"), amount = 100000},
    {name = "100k AMBIENT_JOB_AMMUNATION_DELIVERY", hash = joaat("SERVICE_EARN_AMBIENT_JOB_AMMUNATION_DELIVERY"), amount = 100000},
    {name = "90k GANGOPS_SETUP", hash = joaat("SERVICE_EARN_GANGOPS_SETUP"), amount = 90000},
    {name = "80k AMBIENT_JOB_DEAD_DROP", hash = joaat("SERVICE_EARN_AMBIENT_JOB_DEAD_DROP"), amount = 80000},
    {name = "80k AMBIENT_JOB_HOT_TARGET_DELIVER", hash = joaat("SERVICE_EARN_AMBIENT_JOB_HOT_TARGET_DELIVER"), amount = 80000},
    {name = "75k ARENA_CAREER_TIER_PROGRESSION_3", hash = joaat("SERVICE_EARN_ARENA_CAREER_TIER_PROGRESSION_3"), amount = 75000},
    {name = "70k AMBIENT_JOB_XMAS_MUGGER", hash = joaat("SERVICE_EARN_AMBIENT_JOB_XMAS_MUGGER"), amount = 70000},
    {name = "65k IMPORT_EXPORT", hash = joaat("SERVICE_EARN_IMPORT_EXPORT"), amount = 65000},
    {name = "60k FROM_CLUB_MANAGEMENT_PARTICIPATION", hash = joaat("SERVICE_EARN_FROM_CLUB_MANAGEMENT_PARTICIPATION"), amount = 60000},
    {name = "60k NIGHTCLUB_DANCING_AWARD", hash = joaat("SERVICE_EARN_NIGHTCLUB_DANCING_AWARD"), amount = 60000},
    {name = "55k ARENA_CAREER_TIER_PROGRESSION_2", hash = joaat("SERVICE_EARN_ARENA_CAREER_TIER_PROGRESSION_2"), amount = 55000},
    {name = "50k FROM_BUSINESS_BATTLE", hash = joaat("SERVICE_EARN_FROM_BUSINESS_BATTLE"), amount = 50000},
    {name = "50k ISLAND_HEIST_DJ_MISSION", hash = joaat("SERVICE_EARN_ISLAND_HEIST_DJ_MISSION"), amount = 50000},
    {name = "50k ARENA_SKILL_LVL_AWARD", hash = joaat("SERVICE_EARN_ARENA_SKILL_LVL_AWARD"), amount = 50000},
    {name = "50k AMBIENT_JOB_GANG_CONVOY", hash = joaat("SERVICE_EARN_AMBIENT_JOB_GANG_CONVOY"), amount = 50000},
    {name = "50k COLLECTABLES_SIGNAL_JAMMERS_COMPLETE", hash = joaat("SERVICE_EARN_COLLECTABLES_SIGNAL_JAMMERS_COMPLETE"), amount = 50000},
    {name = "50k AMBIENT_JOB_HELI_HOT_TARGET", hash = joaat("SERVICE_EARN_AMBIENT_JOB_HELI_HOT_TARGET"), amount = 50000},
    {name = "50k ACID_LAB_SELL_PARTICIPATION", hash = joaat("SERVICE_EARN_ACID_LAB_SELL_PARTICIPATION"), amount = 50000},
    {name = "50k FROM_CONTRABAND", hash = joaat("SERVICE_EARN_FROM_CONTRABAND"), amount = 50000},
    {name = "50k CASINO_AWARD_HIGH_ROLLER_GOLD", hash = joaat("SERVICE_EARN_CASINO_AWARD_HIGH_ROLLER_GOLD"), amount = 50000},
    {name = "50k CASINO_AWARD_MISSION_THREE_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_THREE_FIRST_TIME"), amount = 50000},
    {name = "50k GOON", hash = joaat("SERVICE_EARN_GOON"), amount = 50000},
    {name = "50k FIXER_AWARD_PHONE_HIT", hash = joaat("SERVICE_EARN_FIXER_AWARD_PHONE_HIT"), amount = 50000},
    {name = "50k CASINO_AWARD_MISSION_FOUR_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_FOUR_FIRST_TIME"), amount = 50000},
    {name = "50k TAXI_JOB", hash = joaat("SERVICE_EARN_TAXI_JOB"), amount = 50000},
    {name = "50k CASINO_AWARD_MISSION_ONE_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_ONE_FIRST_TIME"), amount = 50000},
    {name = "50k AMBIENT_JOB_SHOP_ROBBERY", hash = joaat("SERVICE_EARN_AMBIENT_JOB_SHOP_ROBBERY"), amount = 50000},
    {name = "50k ARENA_WAR", hash = joaat("SERVICE_EARN_ARENA_WAR"), amount = 50000},
    {name = "50k CASINO_AWARD_MISSION_FIVE_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_FIVE_FIRST_TIME"), amount = 50000},
    {name = "50k CASINO_AWARD_LUCKY_LUCKY", hash = joaat("SERVICE_EARN_CASINO_AWARD_LUCKY_LUCKY"), amount = 50000},
    {name = "50k AMBIENT_JOB_PASS_PARCEL", hash = joaat("SERVICE_EARN_AMBIENT_JOB_PASS_PARCEL"), amount = 50000},
    {name = "50k TUNER_CAR_CLUB_MEMBERSHIP", hash = joaat("SERVICE_EARN_TUNER_CAR_CLUB_MEMBERSHIP"), amount = 50000},
    {name = "50k CASINO_AWARD_MISSION_TWO_FIRST_TIME", hash = joaat("SERVICE_EARN_CASINO_AWARD_MISSION_TWO_FIRST_TIME"), amount = 50000},
    {name = "50k AMBIENT_JOB_HOT_TARGET_KILL", hash = joaat("SERVICE_EARN_AMBIENT_JOB_HOT_TARGET_KILL"), amount = 50000}
}

for i, v in ipairs(Options) do
    menu.add_feature(v.name, "action", transactions, function()
        trigger_transaction(v.hash, v.amount)
    end)
end

