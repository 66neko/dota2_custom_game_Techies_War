--常数
local unit_entindex = {}
local rules_flag = 1
MAX_LEVEL = 20 --最大英雄等级
XP_PER_LEVEL_TABLE = {} --经验表
for i=1,MAX_LEVEL do 
	XP_PER_LEVEL_TABLE[i] = i * 100 
end 


if CBoomGameMode == nil then
	CBoomGameMode = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	PrecacheResource("particle", "particles/econ/items/techies/techies_arcana/techies_suicide_base_arcana.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/techies/techies_arcana/techies_base_attack_arcana_a.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_deafening_blast.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_deafening_blast_knockback_debuff.vpcf", context)	
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)
	PrecacheResource("particle", "particles/units/heroes/hero_bane/bane_enfeeble.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_enigma/enigma_blackhole.vpcf", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CBoomGameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function CBoomGameMode:InitGameMode()
	print( "boom_game is loaded." )
	local GameMode = GameRules:GetGameModeEntity() 
	--开始时间设置
	GameRules:SetPreGameTime(15.0) --[[Returns:void
	Sets the amount of time players have between picking their hero and game start.
	]]
	GameRules:SetHeroSelectionTime(15.0) --[[Returns:void
	Sets the amount of time players have to pick their hero.
	]]
	--设置神符刷新间隔1分钟
	GameRules:SetRuneSpawnTime(60) --[[Returns:void
	Sets the amount of time between rune spawns.
	]]
	--允许选择重复英雄
	GameRules:SetSameHeroSelectionEnabled(true) --[[Returns:void
	When true, players can repeatedly pick the same hero.
	]]
	--设置最	大英雄等级
	GameMode:SetCustomHeroMaxLevel(MAX_LEVEL)
	--设置经验表
	--GameMode:SetUseCustomHeroLevels(true)
	--GameMode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
	--禁止显示推荐装备
	GameMode:SetRecommendedItemsDisabled(true)
	--关闭偷塔保护
	GameMode:SetTowerBackdoorProtectionEnabled(false)
	--设置禁止买活
	GameMode:SetBuybackEnabled(false)
	--设置迷雾规则
	CBoomGameMode:CloseFogOfWar()
	--打开计时器部分
	--CBoomGameMode:ThisThinker()
	--监听器
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(CBoomGameMode, "OnNPCSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CBoomGameMode, "OnNPCKilled"), self)
	--ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CBoomGameMode,"OnGameRulesStateChange"), self)
end

--监听单位创建或重生
function CBoomGameMode:OnNPCSpawned( keys )
	local unit = EntIndexToHScript(keys.entindex) --[[Returns:handle
	Turn an entity index integer to an HScript representing that entity's script instance.
	]]
	if unit:GetUnitName() == "npc_dota_techies_land_mine" then
		unit:SetBaseHealthRegen(-5) --[[Returns:void
				No Description Set
				]]
		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("npc_dota_techies_land_mine_time"),
			function (  )
				if unit:GetHealth() < 5 then
					local suicide_damage = {victim=unit, 
						attacker=unit,         --造成伤害的单位
						damage=2,
						damage_type=DAMAGE_TYPE_PURE}
					ApplyDamage(suicide_damage)
					return nil
				end
				if not(unit:IsAlive()) then
					return nil
				else
					return 1
				end
			end,0)
	end
	--techies创建 
	if unit:GetUnitName() == "npc_dota_hero_techies" then
		if unit_entindex[keys.entindex] == 1 then
		else
			unit_entindex[keys.entindex] = 1
			CBoomGameMode:ThisThinker(unit)
		end
	end
	--游戏规则提醒
	if rules_flag == 1 then
		CBoomGameMode:OnOpen()
		rules_flag = 0
		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("game_rules_time"),
			function (  )
				rules_flag = 1
				return nil
			end,120)
	end
end

--监听单位被击杀事件
function CBoomGameMode:OnNPCKilled( keys )
	local unit = EntIndexToHScript(keys.entindex_killed)
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	local time_respawn = unit:GetLevel()
	if time_respawn>10 then
		time_respawn = 10
	end
	if unit:IsHero() then
		if keys.entindex_attacker == keys.entindex_killed then
			unit:SetTimeUntilRespawn(5)
		else
			unit:SetTimeUntilRespawn(time_respawn+4)
		end
	end
	--判断游戏胜负
	if unit:IsHero() then
		if PlayerResource:GetTeamKills(attacker:GetTeam()) >= 50 then
			GameRules:SetGameWinner(attacker:GetTeam()) --[[Returns:void
			Makes ths specified team win
			]]
		end
	end
end

--监听游戏状态改变
function CBoomGameMode:OnGameRulesStateChange( keys )
	--获取游戏进度
	local newState = GameRules:State_Get() 
	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CBoomGameMode:OnOpen()
	end
end
--定时关闭战争迷雾
function CBoomGameMode:CloseFogOfWar( )
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("game_colse_fogofwar"),
		function (  )
			GameRules:GetGameModeEntity():SetFogOfWarDisabled(true) 
			GameRules:SendCustomMessage("战争迷雾关闭,快定位对手位置", 0, 1) 
			--print("OFF")
			GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("game_colse_fogofwar_2"),
				function (  )
					GameRules:GetGameModeEntity():SetFogOfWarDisabled(false)
					GameRules:SendCustomMessage("战争迷雾关闭", 0, 1) 
					--print("ON")
					return nil
				end,10)
			return 60
		end,60)
end

--计时器部分（自动增加经验金钱等）
function CBoomGameMode:ThisThinker(unit)
	local point_center = Vector(4288,3584,512)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("game_give_exp"),
		function (  )
			unit:AddExperience(25, 0,false,false)
			if ((unit:GetAbsOrigin()-point_center):Length()) <= 1800 then
				unit:AddExperience(35, 0,false,false)
			end
			if ((unit:GetAbsOrigin()-point_center):Length()) <= 900 then
				unit:AddExperience(40, 0,false,false)
			end
			return 7
		end,1)
end
function CBoomGameMode:OnOpen( )
	local text = "游戏开始，越靠近地图中心获得的经验值更多"
	GameRules:SendCustomMessage(text, 0, 1) --[[Returns:void
	Displays a line of text in the left textbox (where usually deaths/denies/buysbacks are announced). This function takes restricted HTML as input! (&lt;br&gt;,&lt;u&gt;,&lt;font&gt;)
	]]
	GameRules:SendCustomMessage("击杀数超过50的队伍将会获得游戏胜利", 0, 1)
end