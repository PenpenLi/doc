require("init_ui")

UI.MyFrame1:Show(true)
UI.m_grid1:AutoSize()

if not CURRENT_MODE then
	return
end

-- 加載監視器
local function topercentstring(percent, is_percentage)
	return string.format("%0.1f%%", is_percentage and percent or percent * 100)
end
scheduler.scheduleGlobal(function()
	local grid = UI.m_grid1
	if app.battle then
		grid:ClearGrid()
		local heroes = app.battle:getHeroes()
		for index, hero in ipairs(heroes) do
			index = index
			grid:SetCellValue(index - 1, 0, tostring(hero:getDisplayName()))
			grid:SetCellValue(index - 1, 1, tostring(hero:getLevel()))
			grid:SetCellValue(index - 1, 2, tostring(hero:getHp()))
			grid:SetCellValue(index - 1, 3, tostring(hero:getMaxHp()))
			grid:SetCellValue(index - 1, 4, tostring(hero:getAttack()) .. "(" .. tostring(topercentstring(hero:getTargetPhysicalArmorCoefficient())) .. ")" .. "(" .. tostring(topercentstring(hero:getTargetMagicArmorCoefficient())) .. ")")
			grid:SetCellValue(index - 1, 5, tostring(hero:getPhysicalArmor()))
			grid:SetCellValue(index - 1, 6, tostring(hero:getMagicArmor()))
			grid:SetCellValue(index - 1, 7, tostring(topercentstring(hero:getPhysicalDamagePercentAttack())))
			grid:SetCellValue(index - 1, 8, tostring(topercentstring(hero:getMagicDamagePercentAttack())))
			grid:SetCellValue(index - 1, 9, tostring(hero:getMoveSpeed()))
			grid:SetCellValue(index - 1, 10, tostring(topercentstring(hero:getCrit(), true)))
			grid:SetCellValue(index - 1, 11, tostring(topercentstring(hero:getCritDamage())))
			grid:SetCellValue(index - 1, 12, tostring(topercentstring(hero:getDodge(), true)))
			grid:SetCellValue(index - 1, 13, tostring(topercentstring(hero:getBlock(), true)))
			grid:SetCellValue(index - 1, 14, tostring(topercentstring(hero:getHit(), true)))
			grid:SetCellValue(index - 1, 15, tostring(topercentstring(hero:getMaxHaste())))
		end
		local enemies = app.battle:getEnemies()
		for index, enemy in ipairs(enemies) do
			if index == 5 then
				break
			end

			index = index + 4
			grid:SetCellValue(index - 1, 0, tostring(enemy:getDisplayName()))
			grid:SetCellValue(index - 1, 1, tostring(enemy:getLevel()))
			grid:SetCellValue(index - 1, 2, tostring(enemy:getHp()))
			grid:SetCellValue(index - 1, 3, tostring(enemy:getMaxHp()))
			grid:SetCellValue(index - 1, 4, tostring(enemy:getAttack()) .. "(" .. tostring(topercentstring(enemy:getTargetPhysicalArmorCoefficient())) .. ")" .. "(" .. tostring(topercentstring(enemy:getTargetMagicArmorCoefficient())) .. ")")
			grid:SetCellValue(index - 1, 5, tostring(enemy:getPhysicalArmor()))
			grid:SetCellValue(index - 1, 6, tostring(enemy:getMagicArmor()))
			grid:SetCellValue(index - 1, 7, tostring(topercentstring(enemy:getPhysicalDamagePercentAttack())))
			grid:SetCellValue(index - 1, 8, tostring(topercentstring(enemy:getMagicDamagePercentAttack())))
			grid:SetCellValue(index - 1, 9, tostring(enemy:getMoveSpeed()))
			grid:SetCellValue(index - 1, 10, tostring(topercentstring(enemy:getCrit(), true)))
			grid:SetCellValue(index - 1, 11, tostring(topercentstring(enemy:getCritDamage())))
			grid:SetCellValue(index - 1, 12, tostring(topercentstring(enemy:getDodge(), true)))
			grid:SetCellValue(index - 1, 13, tostring(topercentstring(enemy:getBlock(), true)))
			grid:SetCellValue(index - 1, 14, tostring(topercentstring(enemy:getHit(), true)))
			grid:SetCellValue(index - 1, 15, tostring(topercentstring(enemy:getMaxHaste())))
		end
		grid:AutoSize()
	else

	end
end, 0.5)