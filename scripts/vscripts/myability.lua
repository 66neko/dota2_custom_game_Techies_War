function myability_suicide_attack( keys )
	local caster = keys.caster --施法者
	local point = keys.target_points[1]

	--添加相位移动，避免卡地形
	caster:AddNewModifier(nil, nil, "modifier_phased", {duration=0.7}) --[[Returns:void
	No Description Set
	]]
	local length_ever =  (point - caster:GetAbsOrigin()):Length()
	length_ever = length_ever / 10
	--for i=1,10 do
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("suicide_attack_time"), 
	function( )
	--判断单位是否死亡，是否存在，是否被击晕，是否正在施法
		if caster:IsAlive() and IsValidEntity(caster) and not(caster:IsStunned()) and caster:IsChanneling() then
			local caster_abs = caster:GetAbsOrigin()
		
			if (point - caster_abs):Length()>25 then
				local face = (point - caster_abs):Normalized() 
				local vec = face * length_ever
				caster:SetAbsOrigin(caster_abs + vec) --[[Returns:void
				SetAbsOrigin
				]]
				return 0.049
			else
				return nil
			end
		end
	end ,0)

end
--施法结束后运行myability_suicide_attack_2
function myability_suicide_attack_2( keys)
	local caster = keys.caster
	--自杀
	local damage_1 = 300
	if caster:GetHealth() <= 300 then
		damage_1 = caster:GetHealth() - 1
	end
	local suicide_damage = {victim=caster, 
		attacker=caster,         --造成伤害的单位
		damage=damage_1,
		damage_type=DAMAGE_TYPE_PURE}
	ApplyDamage(suicide_damage)
end
--技能 投掷手雷
function myability_antitank_grenade( keys )
        local caster = keys.caster
        local caster_vec = caster:GetOrigin()
        local point = keys.target_points[1]
 
        --测试的时候不知道为啥导弹一会可以显示一会不行
        --貌似这个导弹有BUG，我快速使用了几次就奔溃了
        local particleName = "particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare.vpcf"
        local particle = ParticleManager:CreateParticle(particleName,PATTACH_WORLDORIGIN,caster)
 
        --控制点0是起始位置
        ParticleManager:SetParticleControl(particle,0,caster_vec)
 
        --控制点1，3，4是终点
        ParticleManager:SetParticleControl(particle,1,point)
        ParticleManager:SetParticleControl(particle,3,point)
        ParticleManager:SetParticleControl(particle,4,point)
 
        --控制点2是控制导弹发射速率
        local xyz = 1000
        ParticleManager:SetParticleControl(particle,2,Vector(xyz,xyz,xyz))
 
        --(caster_vec - point):Length()是计算两点间的距离
        --加200呢是因为误差，不加200还没到地面就嘣
        local time = ((caster_vec - point):Length() + 200) / xyz
 		
        --开始计时器，time秒之后删除特效
        GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_3"),
                function( )
                		local boom = CreateUnitByName("npc_dota_techies_land_mine", point, false, caster, caster, caster:GetTeam() ) --[[Returns:handle
                		Creates a DOTA unit by its dota_npc_units.txt name ( szUnitName, vLocation, bFindClearSpace, hNPCOwner, hUnitOwner, iTeamNumber )
                		]]
                		EmitSoundOn("Hero_Techies.Suicide", boom)
                		boom:AddAbility("antitank_grenade_unit") --[[Returns:void
                		Add an ability to this unit by name.
                		]]
                		boom:FindAbilityByName("antitank_grenade_unit"):SetLevel(keys.ability:GetLevel())
                		boom:ForceKill(true)
                        ParticleManager:DestroyParticle(particle,false)
                        return nil
                end,time)
end

--技能 流星炸弹
function myability_meteor( keys )
	local radius = 800 --范围
	local particleName = "particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare.vpcf"
	local particleName_2 = "particles/units/heroes/hero_invoker/invoker_sun_strike.vpcf"
	local point = keys.target_points[1]
	local caster = keys.caster
	local xyz = 800 --导弹发射速率
	local x = 1
	local y = 1
	local i = 1 --循环计数
	local random_vector = Vector(1,1,1)
	local time = (1024-350) / xyz
	local ff = {1,-1} --正负因数
	--print(ff[1])
	--print(point)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_meteor"),
		function (  )
			if i <= 40 then
				x = RandomFloat(0,radius)
				y = RandomFloat( math.sqrt(radius*radius - x*x) ,math.sqrt(radius*radius - x*x) * -1)
				random_vector = Vector(point.x+ff[RandomInt(1, 2)]*x,point.y+ff[RandomInt(1, 2)]*y,point.z)
				--print(random_vector)
				--创建导弹特效
				local particle = ParticleManager:CreateParticle(particleName,PATTACH_WORLDORIGIN,caster)
				--控制点0是起始位置
        		ParticleManager:SetParticleControl(particle,0,Vector(random_vector.x,random_vector.y,1024))
				--控制点1，3，4是终点
        		ParticleManager:SetParticleControl(particle,1,random_vector)
       			ParticleManager:SetParticleControl(particle,3,random_vector)
        		ParticleManager:SetParticleControl(particle,4,random_vector)
        		--控制点2是控制导弹发射速率
      			ParticleManager:SetParticleControl(particle,2,Vector(-xyz,0,0))
      			local random_vector_unit = random_vector --局部变量爆炸点
 				GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_meteor_2"),
                	function( )
                			ParticleManager:DestroyParticle(particle,false)
                			local boom = CreateUnitByName("npc_dota_techies_land_mine", random_vector_unit, false, caster, caster, caster:GetTeam() ) --[[Returns:handle
                			Creates a DOTA unit by its dota_npc_units.txt name ( szUnitName, vLocation, bFindClearSpace, hNPCOwner, hUnitOwner, iTeamNumber )
                			]]
                			EmitSoundOn("Hero_Techies.Suicide", boom)
                			boom:AddAbility("antitank_grenade_unit") --[[Returns:void
                			Add an ability to this unit by name.
                			]]
                			boom:FindAbilityByName("antitank_grenade_unit"):SetLevel(keys.ability:GetLevel()+4)
                			boom:ForceKill(true)
                			--创建爆炸特效
                			particle = ParticleManager:CreateParticle(particleName_2,PATTACH_WORLDORIGIN,caster)
                			--控制点0是特效位置
        					ParticleManager:SetParticleControl(particle,0,random_vector_unit)
        					GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_meteor_3"),
        						function( )
        							ParticleManager:DestroyParticle(particle,false)
        							return nil
        						end,5)
                        	return nil
                	end,time)
				--发射间隔 0.2秒
				i = i + 1
				return 0.2
			else
				return nil
			end
		end,0)
end

--技能 超声波守卫
function myability_wave_wrad( keys )
	local caster = keys.caster
	local point = keys.target_points[1]
	local x = 1
	local y = 1
	local radius = 400
	local ff = {1,-1} --正负因数
	local i = 6 --波次数
	local boom = CreateUnitByName("npc_dota_techies_stasis_trap", point, false, caster, caster, caster:GetTeam() )
	boom:AddAbility("wave_wrad_unit")
	boom:FindAbilityByName("wave_wrad_unit"):SetLevel(keys.ability:GetLevel())
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_wave_wrad"),
		function (  )
			if i >= 0 then
				x = RandomFloat(0,radius)
				y = RandomFloat( math.sqrt(radius*radius - x*x) ,math.sqrt(radius*radius - x*x) * -1)
				local random_vector = Vector(point.x+ff[RandomInt(1, 2)]*x,point.y+ff[RandomInt(1, 2)]*y,point.z)
				boom:SetForwardVector(random_vector - point) 
				boom:CastAbilityOnPosition(random_vector, boom:FindAbilityByName("wave_wrad_unit"), caster:GetPlayerOwnerID()) 
				EmitSoundOn("Hero_Techies.StasisTrap.Stun", boom)
				i = i - 1
				return 0.5
			else
				boom:ForceKill(true)
				return nil
			end
		end,0)
end

--技能 混乱黑洞
function myability_black_chaos( keys )
	local caster = keys.caster
	local point = keys.target_points[1]
	local radius = 500
	local i = 1
	local x = 1
	local y = 1
	local particleName = "particles/units/heroes/hero_enigma/enigma_blackhole.vpcf"
	local particle = ParticleManager:CreateParticle(particleName,PATTACH_WORLDORIGIN,caster)
	--控制点0，1是特效位置
    ParticleManager:SetParticleControl(particle,0,point)
    ParticleManager:SetParticleControl(particle,1,point)
    --声音
    caster:EmitSound("Hero_Enigma.Black_Hole") --[[Returns:void
     
    ]]
	local targets = FindUnitsInRadius(caster:GetTeam(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, true)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_black_chaos"),
		function (  )
			if i<= 5 then
				for i,unit in pairs(targets) do
					local damageTable = {victim=unit,    --受到伤害的单位
					attacker=caster,          --造成伤害的单位
		 			damage=45+(keys.ability:GetLevel()*25),
		 			damage_type=DAMAGE_TYPE_MAGICAL}
		 			ApplyDamage(damageTable)    --造成伤害
		 			x = RandomFloat(radius*-1,radius)
		 			y = RandomFloat( math.sqrt(radius*radius - x*x) ,math.sqrt(radius*radius - x*x) * -1)
					unit:SetAbsOrigin(Vector(point.x+x,point.y+y,point.z)) --[[Returns:void
					SetAbsOrigin
					]]
					unit:EmitSound("Hero_Enigma.MaleficeTick") --[[Returns:void
					 
					]]
				end
				i = i + 1
				return 1
			else
				ParticleManager:DestroyParticle(particle,false)
				caster:StopSound("Hero_Enigma.Black_Hole") --[[Returns:void
				Stops a named sound playing from this entity.
				]]
				return nil
			end
		end,0.5)
end

--技能 获取金钱经验
function myability_auto_exp_gold( keys )
	local caster = keys.caster
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("myability_auto_exp_gold"),
		function (  )
			caster:AddExperience(25, false) --[[Returns:bool
			Adds experience to this unit.
			]]
			return 10
		end,0)
end
	