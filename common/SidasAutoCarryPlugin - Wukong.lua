--[[
 
        Auto Carry Plugin - Wukong/Monkey King Edition
                Author: Roach_
                Version: 1.0c
                Copyright 2013
 
                Dependency: Sida's Auto Carry: Revamped
 
                How to install:
                        Make sure you already have AutoCarry installed.
                        Name the script EXACTLY "SidasAutoCarryPlugin - MonkeyKing.lua" without the quotes.
                        Place the plugin in BoL/Scripts/Common folder.
 
                Features:
                        Combo with Autocarry
                        Harass with Mixed Mode
                        Killsteal with Q / E
                        Farm with Q / E
                        Draw Combo Ranges (With Cooldown Check)
                        Escape Artist(with Flash)
                        Auto Pots/Items
 
                History:
                        Version: 1.0c
                                Added a new Check for using Q in Harass Mode
                                Fixed Harass Function(Many thanks to Sida for his ideea with the DelayedAction)
                                Rewrote Low Checks Functions
                                Added a new Check for Mana Potions
                                        - One for Harass/Farm
                                        - One for Potions
                                Deleted Wooglets Support as an Usable Item
                               
                        Version: 1.0b
                                Fixed Harass Option
                                Changed the way to check if mana is low
                                Added Animation Check
                               
                        Version: 1.0a
                                First release
 
--]]
if myHero.charName ~= "MonkeyKing" then return end
 
local Target
local wEscapeHotkey = string.byte("T")
 
-- Prediction
local qRange, eRange, rRange = 300, 625, 162
 
local FlashSlot = nil
 
local SkillQ = { spellKey = _Q, range = 300, speed = 2, delay = 0, width = 200, configName = "crushingBlow", displayName = "Q (Crushing Blow)", enabled = true, skillShot = false, minions = true, reset = true, reqTarget = false }
local SkillW = { spellKey = _W, range = myHero.range-50, speed = 2, delay = 0, width = 200, configName = "decoy", displayName = "W (Decoy)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = false }
local SkillE = { spellKey = _E, range = 625, speed = 2, delay = 0, width = 200, configName = "nimbusStrilke", displayName = "E (Nimbus Strike)", enabled = true, skillShot = false, minions = false, reset = false, reqTarget = true }
 
local QReady, WReady, EReady, RReady, FlashReady = false, false, false, false, false
 
-- Regeneration
local UsingHPot, UsingMPot, UsingFlask, Recall = false, false, false, false
 
-- Our lovely script
function PluginOnLoadMenu()
        Menu = AutoCarry.PluginMenu
        Menu2 = AutoCarry.MainMenu
        Menu:addParam("wPlugin", "[Cast Options]", SCRIPT_PARAM_INFO, "")
        Menu:addParam("wCombo", "[Combo Options]", SCRIPT_PARAM_INFO, "")
        Menu:addParam("wAutoQ", "Auto Cast Q", SCRIPT_PARAM_ONOFF, true)
        Menu:addParam("wAutoE", "Auto Cast E", SCRIPT_PARAM_ONOFF, true)
        Menu:addParam("wAutoR", "Auto Cast R(When Killable)", SCRIPT_PARAM_ONOFF, false)
        Menu:permaShow("wPlugin")
       
        Menu:addParam("wGap", "", SCRIPT_PARAM_INFO, "")
       
        Menu:addParam("wKS", "[Kill Steal Options]", SCRIPT_PARAM_INFO, "")
        Menu:addParam("wKillsteal", "Auto Kill Steal with E / Q", SCRIPT_PARAM_ONOFF, true)
        Menu:permaShow("wKS")
        Menu:permaShow("wKillsteal")
       
        Menu:addParam("wGap", "", SCRIPT_PARAM_INFO, "")
       
        Menu:addParam("wMisc", "[Misc Options]", SCRIPT_PARAM_INFO, "")
        -- Menu:addParam("wAutoLVL", "Auto Level Spells", SCRIPT_PARAM_ONOFF, false)
        Menu:addParam("wMinMana", "Minimum Mana to Farm/Harass", SCRIPT_PARAM_SLICE, 40, 0, 100, -1)
        Menu:addParam("wEscape", "Escape Artist", SCRIPT_PARAM_ONKEYDOWN, false, wEscapeHotkey)
        Menu:addParam("wEscapeFlash", "Escape: Flash to Mouse", SCRIPT_PARAM_ONOFF, false)
        Menu:permaShow("wMisc")
        Menu:permaShow("wEscape")
       
        Menu:addParam("wGap", "", SCRIPT_PARAM_INFO, "")
       
        Menu:addParam("wH", "[Harass Options]", SCRIPT_PARAM_INFO, "")
        Menu:addParam("wHarassE", "Auto Harass with E", SCRIPT_PARAM_ONOFF, true)
        Menu:addParam("wHarassQ", "Auto Harass with Q", SCRIPT_PARAM_ONOFF, false)
        Menu:addParam("wHarassEscape", "Auto use W after Harass", SCRIPT_PARAM_ONOFF, false)
       
        Menu:addParam("wGap", "", SCRIPT_PARAM_INFO, "")
       
        Menu:addParam("wFarm", "[Farm Options]", SCRIPT_PARAM_INFO, "")
        Menu:addParam("wFarmQ", "Auto Farm with Q", SCRIPT_PARAM_ONOFF, false)
        Menu:addParam("wFarmE", "Auto Clear Lane with E", SCRIPT_PARAM_ONOFF, false)
       
        Extras = scriptConfig("Sida's Auto Carry: "..myHero.charName.." Extras", myHero.charName)
        Extras:addParam("wDraw", "[Draw Options]", SCRIPT_PARAM_INFO, "")
        Extras:addParam("wDQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
        Extras:addParam("wDW", "Draw W Range(Check Cooldowns)", SCRIPT_PARAM_ONOFF, false)
        Extras:addParam("wDE", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
       
        Extras:addParam("wGap", "", SCRIPT_PARAM_INFO, "")
       
        Extras:addParam("wHPMana", "[Auto Pots Options]", SCRIPT_PARAM_INFO, "")
        Extras:addParam("wHP", "Auto Health Pots", SCRIPT_PARAM_ONOFF, true)
        Extras:addParam("wMP", "Auto Auto Mana Pots", SCRIPT_PARAM_ONOFF, true)
        Extras:addParam("wHealth", "Minimum Health for Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
        Extras:addParam("wMana", "Minimum Mana for Pots", SCRIPT_PARAM_SLICE, 50, 0, 100, -1)
end
function PluginOnLoad()
        -- Params/PluginMenu
        PluginOnLoadMenu()
       
        -- Range
        AutoCarry.SkillsCrosshair.range = eRange
end
 
function PluginOnTick()
        if Recall then return end
       
        -- Get Attack Target
        Target = AutoCarry.GetAttackTarget()
 
        -- Checks
        wChecks()
 
        -- Combo, Harass, Killsteal, Escape Combo, Farm - Checks
        wCombo()
        wHarass()
        wKillsteal()
        wEscapeCombo()
        wFarm()
       
        -- Auto Regeneration
        if Extras.wHP and IsLow('Health') and not (UsingHPot or UsingFlask) and (HPReady or FSKReady) then CastSpell((hpSlot or fskSlot)) end
        if Extras.wMP and IsLow('Mana') and not (UsingMPot or UsingFlask) and(MPReady or FSKReady) then CastSpell((mpSlot or fskSlot)) end
end
 
function PluginOnDraw()
        -- Draw Wukong's Range = 625
        local tempColor = { 0xFF0000, 0xFF0000, 0xFF0000 }
       
        if not myHero.dead then
                if Extras.wDQ then
                        if QReady then tempColor[1] = 0x00FF00 end
                        DrawCircle(myHero.x, myHero.y, myHero.z, qRange, tempColor[1])
                end
                if Extras.wDW then
                        if WReady then tempColor[2] = 0x00FF00 end
                        DrawCircle(myHero.x, myHero.y, myHero.z, myHero.range-50, tempColor[2])
                end
                if Extras.wDE then
                        if EReady then tempColor[3] = 0x00FF00 end
                        DrawCircle(myHero.x, myHero.y, myHero.z, eRange, tempColor[3])
                end
        end
end
 
-- Spell Detection
function OnProcessSpell(unit, spell)
        -- Set lastSpell = Last Spell used
        if unit.isMe and lastSpell ~= spell.name then
                lastSpell = spell.name
                PrintChat( unit.charName .. " has used: " .. spell.name )
        end
end
 
-- Object Detection
function PluginOnCreateObj(obj)
        if obj.name:find("TeleportHome.troy") then
                if GetDistance(obj, myHero) <= 70 then
                        Recall = true
                end
        end
        if obj.name:find("Regenerationpotion_itm.troy") then
                if GetDistance(obj, myHero) <= 70 then
                        UsingHPot = true
                end
        end
        if obj.name:find("Global_Item_HealthPotion.troy") then
                if GetDistance(obj, myHero) <= 70 then
                        UsingHPot = true
                        UsingFlask = true
                end
        end
        if obj.name:find("Global_Item_ManaPotion.troy") then
                if GetDistance(obj, myHero) <= 70 then
                        UsingFlask = true
                        UsingMPot = true
                end
        end
end
 
function PluginOnDeleteObj(obj)
        if obj.name:find("TeleportHome.troy") then
                Recall = false
        end
        if obj.name:find("Regenerationpotion_itm.troy") then
                UsingHPot = false
        end
        if obj.name:find("Global_Item_HealthPotion.troy") then
                UsingHPot = false
                UsingFlask = false
        end
        if obj.name:find("Global_Item_ManaPotion.troy") then
                UsingMPot = false
                UsingFlask = false
        end
end
 
-- Primary Functions
function wCombo()
        if Menu.wCombo and Menu2.AutoCarry then
                if ValidTarget(Target) then
                        if QReady and Menu.wAutoQ and GetDistance(Target) < qRange then
                                CastSpell(SkillQ.spellKey, Target)
                        end
                       
                        if EReady and Menu.wAutoE and GetDistance(Target) < eRange then
                                CastSpell(SkillE.spellKey, Target)
                        end
                       
                        if RReady and Menu.wAutoR and (getDmg("R", Target, myHero) * 4) > Target.health and GetDistance(Target) < (rRange - 12) then
                                CastSpell(_R)
                        end
                end
        end
end
 
function wHarass()
        if Menu2.MixedMode then
                if ValidTarget(Target) then
                        if Menu.wHarassE and  EReady and GetDistance(Target) < eRange and not IsLow('Mana Harass') then
                                CastSpell(SkillE.spellKey, Target)
                        end
                       
                        if Menu.wHarassQ and QReady and GetDistance(Target) < qRange then
                                CastSpell(SkillQ.spellKey, Target)
                                myHero:Attack(Target)
                        end
                       
                        if Menu.wHarassEscape and WReady and ((isSpelling("MonkeyKingQAttack") and Menu.wHarassE and Menu.wHarassQ) or (isSpelling("MonkeyKingNimbus") and Menu.wHarassE and not Menu.wHarassQ)) then
                                CastSpell(SkillW.spellKey)
                                wInStealth = true
                                DelayAction(function() wInStealth = false end, 1.5)
                        end
                end
        end
end
 
function wFarm()
        if Menu.wFarmQ and (Menu2.LastHit) and not IsLow('Mana Farm') then
                for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
                        if ValidTarget(minion) and QReady and GetDistance(minion) <= qRange then
                                if minion.health < getDmg("Q", minion, myHero) then
                                        CastSpell(SkillQ.spellKey, minion)
                                        myHero:Attack(minion)
                                end
                        end
                end
        end
        if Menu.wFarmE and (Menu2.LaneClear) and not IsLow('Mana Farm') then
                for _, minion in pairs(AutoCarry.EnemyMinions().objects) do
                        if ValidTarget(minion) and EReady and GetDistance(minion) <= eRange then
                                if minion.health < getDmg("E", minion, myHero) then
                                        CastSpell(SkillE.spellKey, minion)
                                end
                        end
                end
        end
end
 
function wKillsteal()
        if Menu.wKillsteal then
                for _, enemy in pairs(AutoCarry.EnemyTable) do
                        if ValidTarget(enemy) then
                                if QReady and GetDistance(enemy) < qRange and enemy.health < getDmg("Q", enemy, myHero) then
                                        CastSpell(SkillQ.spellKey, enemy)
                                end
                                if EReady and GetDistance(enemy) > qRange and GetDistance(enemy) < eRange and enemy.health < getDmg("E", enemy, myHero) then
                                        CastSpell(SkillE.spellKey, enemy)
                                end
                        end
                end
        end
end
 
function wEscapeCombo()
        if Menu.wEscape then
                if WReady then
                        CastSpell(_W)
                        if Menu.wEscapeFlash and FlashReady and GetDistance(mousePos) > 300 then
                                CastSpell(FlashSlot, mousePos.x, mousePos.z)
                        end
                end
               
                if Menu.wEscapeFlash then
                        myHero:MoveTo(mousePos.x, mousePos.z)
                end
        end
end
 
-- Scondary Functions
function wChecks()
        hpSlot, mpSlot, fskSlot = GetInventorySlotItem(2003), GetInventorySlotItem(2004), GetInventorySlotItem(2041)
 
        if myHero:GetSpellData(SUMMONER_1).name:find("SummonerFlash") then
                FlashSlot = SUMMONER_1
        elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerFlash") then
                FlashSlot = SUMMONER_2
        end
 
        QReady = (myHero:CanUseSpell(SkillQ.spellKey) == READY)
        WReady = (myHero:CanUseSpell(_W) == READY)
        EReady = (myHero:CanUseSpell(SkillE.spellKey) == READY)
        RReady = (myHero:CanUseSpell(_R) == READY)
        HPReady = (hpSlot ~= nil and myHero:CanUseSpell(hpSlot) == READY)
        MPReady = (mpSlot ~= nil and myHero:CanUseSpell(mpSlot) == READY)
        FSKReady = (fskSlot ~= nil and myHero:CanUseSpell(fskSlot) == READY)
 
        FlashReady = (FlashSlot ~= nil and myHero:CanUseSpell(FlashSlot) == READY)
       
        if wInStealth then
                AutoCarry.CanAttack = false
        else
                AutoCarry.CanAttack = true
        end
end
 
function isSpelling(spell)
        if lastSpell == spell then
                return true
        else
                return false
        end
end
 
function IsLow(Name)
        if Name == 'Mana' then
                if (myHero.mana / myHero.maxMana) <= (Extras.wMana / 100) then
                        return true
                else
                        return false
                end
        end
        if Name == 'Mana Harass' or Name == 'Mana Farm' then
                if (myHero.mana / myHero.maxMana) <= (Menu.wMinMana / 100) then
                        return true
                else
                        return false
                end
        end
        if Name == 'Health' then
                if (myHero.health / myHero.maxHealth) <= (Extras.wWHealth / 100) then
                        return true
                else
                        return false
                end
        end
end
