local QStaticDatabase = class("QStaticDatabase")

function QStaticDatabase:sharedDatabase()
	if app._database == nil then
        app._database = QStaticDatabase.new()
    end
    return app._database
end

function QStaticDatabase:ctor()
	-- load global static database
    self:reloadStaticDatabase()
end

function QStaticDatabase:loadLocalIndex()
    return QStaticDatabase.loadIndex(CCFileUtils:sharedFileUtils():getFileData("static/index"))
end

function QStaticDatabase:loadWritableIndex()
    local fileutil = CCFileUtils:sharedFileUtils()
    return QStaticDatabase.loadIndex(fileutil:getFileData(fileutil:getWritablePath() .. "index"))
end

function QStaticDatabase:loadIndexFile()
    local fileutil = CCFileUtils:sharedFileUtils()
    local inWritablePath = fileutil:isFileExist(fileutil:getWritablePath() .. "index")
    local disable_download = QDownloader:staticIsDisableDownload()

    if inWritablePath and not(disable_download) then
        return self:loadWritableIndex()
    else
        return self:loadLocalIndex()
    end
end

function QStaticDatabase.loadIndex(content)
    local index = {}
    for _, line in ipairs(string.split(content, "\n")) do
        if line:sub(1, 5) == "#MD5:" then -- 杩欓噷鏄竴涓潪甯哥壒娈婄殑鍦版柟锛屽疄闄呯敤閫旀槸鐢ㄤ簬璁剧疆瑙ｅ瘑缃戠粶浼犺緭鐨刱ey
            local key = string.trim(string.split(line, " ")[2])
            QUtility:updateText(key)
        elseif line:sub(1, 1) ~= '#' then -- the first line is the time stamp
            line = string.trim(line)
            if string.len(line) > 0 then
                values = string.split(line, " ")

                -- nzhang: 浠ラ槻鏂囦欢鍚嶆湁绌烘牸, 涓嶈兘搴斿澶氫釜绌烘牸杩炲湪涓�璧风殑鎯呭喌
                local values_len = #values
                local name_entry_number = values_len - 3
                local name = values[1]
                local count = 2
                while count <= name_entry_number do
                    name = name .. " " .. values[count]
                    count = count + 1
                end

                index[name] = {
                    name = name,
                    md5 = values[name_entry_number + 1],
                    size = tonumber(values[name_entry_number + 2]),
                    gz = tonumber(values[name_entry_number + 3]),
                    retry = 0
                }
            end
        end
    end

    return index
end

local function shrink_object_index(t, key)
    return t.__inner_array[t.__colnames[key]]
end

local function get_shrink_object_index(__inner_array, __colnames)
    return function(t, key)
        return __inner_array[__colnames[key]]
    end
end

local function shrink_object_pairs(t)
  return function(t, k)
    local v
    local __colnames = t.__colnames
    local __inner_array = t.__inner_array
    repeat
        k, index = next(__colnames, k)
        v = __inner_array[index]    
    until k == nil or v ~= nil
    return k, v
  end, t, nil
end

local function get_shrink_object_pairs(__inner_array, __colnames)
    return function(t)
      return function(t, k)
        local v
        repeat
            k, index = next(__colnames, k)
            v = __inner_array[index]    
        until k == nil or v ~= nil
        return k, v
      end, t, nil
    end
end

local function clone_shrink(shrink_obj)
    if shrink_obj.__inner_array == nil then
        return clone(shrink_obj)
    end

    local obj = {}
    local __inner_array = shrink_obj.__inner_array
    local __colnames = shrink_obj.__colnames
    for k, v in pairs(__colnames) do
        obj[k] = __inner_array[v]
    end

    return obj
end

local function shrinkObject(colnames_bykey, colnames_byindex, obj)
    local raw_obj = obj
    local obj = {}
    local obj_inner_array = {}

   obj.__colnames = colnames_bykey
   obj.__inner_array = obj_inner_array

    for key, value in pairs(raw_obj) do
        local col_index = colnames_bykey[key]
        if col_index == nil then
            table.insert(colnames_byindex, key)
            col_index = #colnames_byindex
            colnames_bykey[key] = col_index
        end
        obj_inner_array[col_index] = value
    end

    -- setmetatable(obj, {__index = get_shrink_object_index(obj_inner_array, colnames_bykey), __pairs = get_shrink_object_pairs(obj_inner_array, colnames_bykey)})
    setmetatable(obj, {__index = shrink_object_index})

    return obj
end

local function shrinkStaticDatabase(db)
    local raw_db = db
    db = {}
    for chart_name, raw_chart in pairs(raw_db) do
        local chart = {}
        local chart_colnames_bykey = {}
        local chart_colnames_byindex = {}
        for obj_key, raw_obj in pairs(raw_chart) do
            if #raw_obj > 0 then
                local raw_arr = raw_obj
                local arr = {}
                for _, raw_obj in ipairs(raw_arr) do
                    table.insert(arr, shrinkObject(chart_colnames_bykey, chart_colnames_byindex, raw_obj))
                end
                chart[obj_key] = arr
            else
                chart[obj_key] = shrinkObject(chart_colnames_bykey, chart_colnames_byindex, raw_obj)
            end
        end
        db[chart_name] = chart
    end
    return db
end

function QStaticDatabase:reloadStaticDatabase()
    self._staticDatabase = {}

    local contents = {}

    local content = nil
    for name, _ in pairs(self:loadIndexFile()) do
        if string.find(name, "res/static", 1, true) == 1 or string.find(name, "static", 1, true) == 1 then -- only reload res/static/
            local position = string.find(name, ".json", 1, true)
            if position ~= nil and position > 1 then
                content = QUtility:decryptFile(name)
                if content ~= nil then
                    table.insert(contents, {content = content, name = name})
                    content = nil
                end
            end
        end
    end

    for _, obj in ipairs(contents) do
        local subtable = json.decode(obj.content)
        assert(subtable ~= nil, string.format("量表格式错误：%s", obj.name))
        table.merge(self._staticDatabase, subtable)

        obj.content = nil
        obj.name = nil
    end

    collectgarbage()
    -- CCMessageBox("before_shrink " .. tostring(collectgarbage("count")*1024), "")

    -- self._staticDatabase = shrinkStaticDatabase(self._staticDatabase)

    collectgarbage()
    -- CCMessageBox("after_shrink " .. tostring(collectgarbage("count")*1024), "")

    if app.sound ~= nil then
        app.sound:reloadSoundConfig()
    end
end

function QStaticDatabase:getConfiguration()
    return self._staticDatabase.configuration
end

function QStaticDatabase:getArenaAward(rank)
    local vector = self:sharedDatabase()._staticDatabase.arena_awards
    if vector == nil then
        return
    end
    for i, v in pairs(vector) do
        -- local low = string.split(v.condition, ":")
        -- local high = nil
        -- if #low == 1 then
        --     high = low[1]
        --     low = high
        -- else
        --     high = low[2]
        --     low = low[1]
        -- end
        local low = v.rank_lower
        local high = v.rank_upper
        if rank <= tonumber(high) and rank >= tonumber(low) then
            return v, low, high
        end
    end
end

--閲戦挶浣撳姏璐拱閰嶇疆
function QStaticDatabase:getTokenConsumeByType(typeName)
    if typeName == nil then return nil end
    local vector = self:sharedDatabase()._staticDatabase.token_consume
    return vector[typeName]
end

function QStaticDatabase:getTokenConsume(type, time)
    local vector = self:sharedDatabase()._staticDatabase.token_consume
    for _, good in ipairs(vector[type]) do
        if good.type == type and good.consume_times == time then
            return good
        end
    end
    return nil 
end
--config.award_type_exp 缁忛獙
--config.award_type_money 閲戦挶
--config.award_type_token_money 浠ｅ竵
--config.award_type_team_exp 鍥㈤槦缁忛獙
--config.award_type_item 鐗╁搧
function QStaticDatabase:getConfig()
    return global.config
end

function QStaticDatabase:getLocalizationByKey(key)
    if key == nil then return nil end
    
    return self._staticDatabase.localization[key][global.language]
end

function QStaticDatabase:getCharacterByID(id)
    if id == nil then return nil end
    
    return self._staticDatabase.character[tostring(id)]
end

-- return game tips from the id of dungeon @qinyuanji
function QStaticDatabase:getGameTipsByID(dungeon_id)
    if dungeon_id == nil then return nil end

    return self._staticDatabase.gametips[dungeon_id]
end

-- return random names @qinyuanji
function QStaticDatabase:getNamePlayers()
    return self._staticDatabase.name_players
end

-- return default avatars @qinyuanji
function QStaticDatabase:getDefaultAvatars()
    return self._staticDatabase.head_default
end

function QStaticDatabase:getCharacter()
    return self._staticDatabase.character
end

function QStaticDatabase:getCharacterIDs()
    return table.keys(self._staticDatabase.character)
end

function QStaticDatabase:getCharacterDisplayIds()
    return table.keys(self._staticDatabase.character_display)
end

function QStaticDatabase:getCharacterDisplayByActorID(actorId)
    if actorId == nil then return nil end

    local character = self:getCharacterByID(actorId)
    return self._staticDatabase.character_display[tostring(character.display_id)]
end

function QStaticDatabase:getCharacterDisplayByID(id)
    if id == nil then return nil end

    return self._staticDatabase.character_display[tostring(id)]
end

function QStaticDatabase:getMonstersById(id)
    return self._staticDatabase.dungeon_monster[id];
end

function QStaticDatabase:insertMonster(id, tbl)
    if self._staticDatabase.dungeon_monster[id] == nil then
        self._staticDatabase.dungeon_monster[id] = {}
        table.insert(self._staticDatabase.dungeon_monster[id], tbl)
    else
        table.insert(self._staticDatabase.dungeon_monster[id], tbl)
    end
end

function QStaticDatabase:clearMonstersById(id)
    self._staticDatabase.dungeon_monster[id] = nil
end

--鍐涜濂栧姳
function QStaticDatabase:getRankAwardByID(id)
    if id == nil then
        return nil
    end
    for _,config in pairs(self:sharedDatabase()._staticDatabase.military_awards) do
        if config.id == id then
            return config
        end
    end
    return nil
    -- todo
end

--鍏冲崱鎺夎惤
function QStaticDatabase:getDungeonAwardByID(id)
    if id == nil then
        return nil
    end
    for _,config in pairs(self:sharedDatabase()._staticDatabase.dungeon_awards) do
        if config.id == id then
            return config
        end
    end
    return nil
    -- todo
end

--鑾峰彇鍦板浘閰嶇疆
function QStaticDatabase:getMaps()
    return self._staticDatabase.map_config
end

function QStaticDatabase:getMapAchievement(instanceID)
     if instanceID == nil then return nil end
     return self._staticDatabase.map_achievement[instanceID]
end

function QStaticDatabase:getLuckyDraw(index)
     if index == nil then return nil end
     return self._staticDatabase.lucky_draw[index]
end

function QStaticDatabase:getDungeonConfigByID(id)
    if id == nil then return nil end
    return self._staticDatabase.dungeon_config[id]
end

function QStaticDatabase:getDungeonTargetByID(id)
    if id == nil then return nil end
    return self._staticDatabase.dungeon_target[id]
end

function QStaticDatabase:getDungeonConfigByType(typeid)
    if typeid == nil then return nil end

    local elites = {}
    for k, config in pairs(self._staticDatabase.dungeon_config) do
        for j, configvalue in pairs(config) do
            if configvalue.type == typeid then
                table.insert(elites, configvalue)
            end
        end
    end

    return elites
end

--鎴樻枟鍔涢厤缃�
function QStaticDatabase:getForceConfigByLevel(level)
    if level == nil then return nil end
    for _,value in pairs(self._staticDatabase.force) do
      if value.level == level then
        return value
      end
    end
    return nil
end

--绐佺牬閰嶇疆
-- 绐佺牬 澶╄祴 瑁呭閰嶇疆
function QStaticDatabase:getBreakthroughByTalentLevel(talentID,level)
    if talentID == nil or level == nil or self._staticDatabase.breakthrough[talentID] == nil then return nil end
    for _, config in pairs(self._staticDatabase.breakthrough[talentID]) do 
        if config.breakthrough_level == level then
            return config
        end
    end
    return nil
end

--鏍规嵁澶╄祴鑾峰彇绐佺牬
function QStaticDatabase:getBreakthroughByTalent(talentID)
    if talentID == nil then return nil end
    return self._staticDatabase.breakthrough[talentID]
end

--鏍规嵁鑻遍泟ID鑾峰彇绐佺牬
function QStaticDatabase:getBreakthroughByActorId(actorId)
    if actorId == nil then return nil end
    local heroConfig = self:getCharacterByID(actorId)
    return self:getBreakthroughByTalent(heroConfig.talent)
end

--鏍规嵁鑻遍泟ID鑾峰彇绐佺牬鑻遍泟灞炴�ч厤缃�
function QStaticDatabase:getBreakthroughHeroByActorId(actorId)
    if actorId == nil then return nil end
    return self._staticDatabase.breakthrough_hero[tostring(actorId)]
end

-- 绐佺牬 鑻遍泟 鍔犳垚閰嶇疆
function QStaticDatabase:getBreakthroughByHeroActorLevel(actorId,level)
    if actorId == nil or level == nil or self._staticDatabase.breakthrough_hero[tostring(actorId)] == nil then return nil end
    for _, config in pairs(self._staticDatabase.breakthrough_hero[tostring(actorId)]) do 
        if config.breakthrough_level == level then
            return config
        end
    end
    return nil
end

--杩涢樁閰嶇疆
-- 杩涢樁 鑻遍泟 鍔犳垚閰嶇疆
function QStaticDatabase:getGradeByHeroActorLevel(actorId,level)
    if actorId == nil or level == nil or self._staticDatabase.grade[tostring(actorId)] == nil then return nil end
    for _, config in pairs(self._staticDatabase.grade[tostring(actorId)]) do 
        if config.grade_level == level then
            return config
        end
    end
    return nil
end

function QStaticDatabase:getGradeByHeroId(actorId)
    return self._staticDatabase.grade[tostring(actorId)]
end

function QStaticDatabase:getNeedSoulByHeroActorLevel(actorId,level)
    if actorId == nil or level == nil or self._staticDatabase.grade[tostring(actorId)] == nil then return nil end
    local need = 0
    for i=0,level,1 do
        local config = self:getGradeByHeroActorLevel(actorId,i)
        need = need + config.soul_gem_count
        printInfo("soul_gem:"..need)
    end
    return need
end

--鏍规嵁鑻遍泟纰庣墖ID鑾峰彇鑻遍泟褰撳墠绐佺牬绛夌骇鎵�闇�鏈�澶х鐗囨暟
function QStaticDatabase:getGradeNeedMaxSoulNumByHeroSoulId(soul_gem)
  local actorId = nil
    if soul_gem == nil then return nil end
    for _, config in pairs(self._staticDatabase.grade) do 
       if config[1].soul_gem == tonumber(soul_gem) then
          actorId = config[1].id
       end
    end
  local soulNum = nil
  local heroIsHave = false
  local haveHerosID = remote.herosUtil:getHaveHeroKey()
  for _, value in pairs(haveHerosID) do
    if value == actorId then
      heroIsHave = true
    end
  end
  if heroIsHave == false then
    soulNum = self:getGradeByHeroActorLevel(actorId,0)
  else
    local heroInfo = remote.herosUtil:getHeroByID(actorId)
    soulNum = self:getGradeByHeroActorLevel(actorId,heroInfo.grade + 1)
  end
  return soulNum
end

--鐗╁搧閰嶇疆
function QStaticDatabase:getItemByID(itemID)
    if itemID == nil then return nil end
    itemID = tonumber(itemID)
    for _,item in pairs(self._staticDatabase.item) do
      if item.id == itemID then
        return item
      end
    end
    return nil
end

--璺熸煇灞炴�ц幏鍙栭潪绌洪泦鍚�
function QStaticDatabase:getItemsByProp(prop)
    if prop == nil then return clone(self._staticDatabase.item) end
    local items = {}
    for _,item in pairs(self._staticDatabase.item) do
      if item[prop] ~= nil then
        if type(item[prop]) == "number" then
            if item[prop] > 0 then
                table.insert(items, item)
            end
        else
            table.insert(items, item)
        end
      end
    end
    return items
end

--杩涢樁瑙ｉ攣閰嶇疆
function QStaticDatabase:getHeroGradeSkill(talentID)
    if talentID == nil then return nil end
    return self._staticDatabase.hero_grade_skill[talentID]
end

function QStaticDatabase:getSkillByID(id)
    if id == nil then return nil end

    if self._staticDatabase.skill[id] == nil then
        return nil
    end

    local skill = clone(self._staticDatabase.skill[id])
    if skill.skill_cast ~= nil and self._staticDatabase.skill_cast[skill.skill_cast] ~= nil then
        table.merge(skill, clone_shrink(self._staticDatabase.skill_cast[skill.skill_cast]))
    end
    if skill.skill_animation ~= nil and self._staticDatabase.skill_animation[skill.skill_animation] ~= nil then
        table.merge(skill, clone_shrink(self._staticDatabase.skill_animation[skill.skill_animation]))
    end
    if skill.skill_display ~= nil and self._staticDatabase.skill_display[skill.skill_display] ~= nil then
        table.merge(skill, clone_shrink(self._staticDatabase.skill_display[skill.skill_display]))
    end
    if skill.skill_description ~= nil and self._staticDatabase.skill_description[skill.skill_description] ~= nil then
        table.merge(skill, clone_shrink(self._staticDatabase.skill_description[skill.skill_description]))
    end

    skill.id = id

    return skill
end

function QStaticDatabase:getSound()
    return self._staticDatabase.sound
end

function QStaticDatabase:getSoundById(id)
    if id == nil then return nil end
    return self._staticDatabase.sound[id]
end

-- this function is inefficiently
-- Never use it in game
function QStaticDatabase:getSkillsByName(name)
    if name == nil then return nil end

    local skillIds = {}
    for _, skillInfo in pairs(self._staticDatabase.skill) do
        if skillInfo.name == name then
            table.insert(skillIds, skillInfo.id)
        end
    end
    return skillIds
end

function QStaticDatabase:getSkillsInfoByName(name)
    if name == nil then return nil end

    local skills = {}
    for _, skillInfo in pairs(self._staticDatabase.skill) do
        if skillInfo.name == name then
            local skill = self:getSkillByID(skillInfo.id)
            if skill ~= nil then
                table.insert(skills, skill)
            end
        end
    end
    return skills
end

function QStaticDatabase:getSkillsByNameLevel(name, level)
    if name == nil or level == nil then return nil end

    for _, skillInfo in pairs(self._staticDatabase.skill) do
        if skillInfo.name == name and skillInfo.level == level then
            return self:getSkillByID(skillInfo.id)
        end
    end
    return nil
end

function QStaticDatabase:getTalentByID(id)
    if id == nil then return nil end

    return self._staticDatabase.talent[id]
end

function QStaticDatabase:getBuffByID(id)
    if id == nil then return nil end

    return self._staticDatabase.buff[id]
end

function QStaticDatabase:getTrapByID(id)
    if id == nil then return nil end

    return self._staticDatabase.trap[id]
end

--鍐涜閰嶇疆 鏍规嵁鍐涜Code鑾峰彇鍐涜閰嶇疆
function QStaticDatabase:getRankConfigByCode(rankCode)
    if rankCode == nil then return nil end
    for _,config in pairs(self._staticDatabase.rank) do
        if config.code == rankCode then
            return config
        end
    end
    return nil
end

function QStaticDatabase:getRankConfig()
    return self._staticDatabase.rank
end

--鎴橀槦缁忛獙 绛夌骇閰嶇疆
function QStaticDatabase:getTeamLevelByExperience(experience)
    local level = 1
    -- TBD: binary search 
    for k, el in pairs(self._staticDatabase.team_exp_level) do
        level = el.level
        if experience < el.exp then
            break
        end
    end
    return level
end

function QStaticDatabase:getExperienceByTeamLevel(level)
    if level == nil then return nil end 
    -- TBD: binary search 
    local exp = 1
    for k, el in pairs(self._staticDatabase.team_exp_level) do
        if level == el.level then
            exp = el.exp
            break
        end
    end
    return exp
end

function QStaticDatabase:getTeamConfigByTeamLevel(level)
    if level == nil then return nil end 
    for k, el in pairs(self._staticDatabase.team_exp_level) do
        if level == el.level then
            return el
        end
    end
    return nil
end

function QStaticDatabase:getLevelByExperience(experience)
    local level = 1
    -- TBD: binary search 
    local exp_level = table.sort(self._staticDatabase.exp_level)
    for _, el in pairs(self._staticDatabase.exp_level) do
        level = el.level
        if experience < el.exp then
            break
        end
    end
    return level
end

function QStaticDatabase:getExperienceByLevel(level)
    if level == nil then return nil end 
    -- TBD: binary search 
    local exp = 1
    for k, el in pairs(self._staticDatabase.exp_level) do
        if level == el.level then
            exp = el.exp
            break
        end
    end
    return exp
end

function QStaticDatabase:getTotalExperienceByLevel(level)
    if level == nil then return 0 end 
    -- TBD: binary search 
    local exp = 0
    for k, el in pairs(self._staticDatabase.exp_level) do
        if level > el.level then
            exp = exp + el.exp
        end
    end
    return exp
end

function QStaticDatabase:getLevelCoefficientByLevel(level)
    if level == nil then return nil end

    return self._staticDatabase.level_coefficient[level]
end

function QStaticDatabase:getEffectIds()
    return table.keys(self._staticDatabase.effect)
end

--获取商店npc对话
function QStaticDatabase:getShopTalk(shop_id, talk_type)
  if shop_id == nil or talk_type == nil then return nil end
  local talkWord = nil
  for k, talks in pairs(self._staticDatabase.shop_talk[shop_id]) do
    if talks.event == talk_type then
        local nums = table.nums(talks) - 3
        if nums ~= 0 then
          local num = math.random(nums)
          talkWord = talks["talk"..num]
        end
        return talkWord
    end
  end
end

--获取普通商店刷新时间
function QStaticDatabase:getGeneralShopRefreshTime()
  return self._staticDatabase.shop["1"].refresh_times
end

--根据shopId和当前刷新次数获取当前刷新所需符石
function QStaticDatabase:getTokenByRefreshCount(shopId, refreshCount)
  local shopType = nil
  if shopId == "1" then
    shopType = "refresh_shop"
    valueType = "token_cost"
  elseif shopId == "2" then
    shopType = "refresh_shop_1"
    valueType = "token_cost"
  elseif shopId == "3" then
    shopType = "refresh_shop_2"
    valueType = "token_cost"
  elseif shopId == "4" then
    shopType = "refresh_arena_shop"
    valueType = "arena_money"
  elseif shopId == "5" then
    shopType = "refresh_sunwell_shop"
    valueType = "sunwell_money"
  end
  local refreshShop = self._staticDatabase.token_consume[shopType]
  for k, value in pairs(refreshShop) do
    if value.consume_times == refreshCount + 1 then
      return value[valueType]
    end
  end
  return refreshShop[10][valueType]
end

--根据当前年月获取签到奖励表
function QStaticDatabase:getDailySignInItmeByMonth(date)
  return self._staticDatabase.check_in[date]
end

--根据当前签到次数获取奖励表
function QStaticDatabase:getAddUpSignInItmeByMonth(signNum, signAward)
  local data = self._staticDatabase.check_in_add
  local index = {}
  local nowNum = nil
  local maxNum = nil
  for k, value in pairs(data) do
    table.insert(index, value.times)
  end
  for i = 1, #index - 1, 1 do 
    for j = i + 1, #index, 1 do 
      if index[j] < index[i] then
        local var = nil
        var = index[i] 
        index[i] = index[j]
        index[j] = var
      end
    end
  end
  
  if signNum <= index[1] and signAward < index[1] then
    nowNum = signNum
    maxNum = data[tostring(index[1])].times
    return data[tostring(index[1])], nowNum, maxNum
  elseif signNum == index[1] and signAward == index[1] then
    nowNum = signNum
    maxNum = data[tostring(index[2])].times
    return data[tostring(index[2])], nowNum, maxNum
  elseif signNum >= index[#index] and signAward >= index[#index] then
    nowNum = signNum
    maxNum = signAward + 7
    return data[tostring(index[#index])], nowNum, maxNum
  end
  
  for i = 1, #index, 1 do
    if signNum >= index[i] and signAward == index[i] then
      nowNum = signNum
      maxNum = data[tostring(index[i + 1])].times
      return data[tostring(index[i + 1])], nowNum, maxNum
    elseif signNum == index[i + 1] and signAward == index[i] then
      nowNum = signNum
      maxNum = data[tostring(index[i + 1])].times
      return data[tostring(index[i + 1])], nowNum, maxNum
    elseif signNum == index[i] and signAward == index[i] then
      nowNum = signNum
      maxNum = data[tostring(index[i + 1])].times
      return data[tostring(index[i])], nowNum, maxNum
    end
  end
end

--姣忔棩浠诲姟
function QStaticDatabase:getTask()
    return self._staticDatabase.tasks
end

-- mark effect value
function QStaticDatabase:getEffectFileByID(id)
    if id == nil then return nil end

    if self._staticDatabase.effect[id] == nil then
        assert(false, "effect id: " .. id .. " is not found")
        return nil, nil
    end
    return self._staticDatabase.effect[id].file, self._staticDatabase.effect[id].file_back
end

function QStaticDatabase:getEffectScaleByID(id)
    if id == nil then return nil end

    local scale = self._staticDatabase.effect[id].scale
    if scale == nil then
        scale = 1.0
    end
    return scale
end

function QStaticDatabase:getEffectPlaySpeedByID(id)
    if id == nil then return nil end

    local playSpeed = self._staticDatabase.effect[id].play_speed
    if playSpeed == nil then
        playSpeed = 1.0
    end
    return playSpeed
end

function QStaticDatabase:getEffectOffsetByID(id)
    if id == nil then return 0, 0 end

    local offsetX = self._staticDatabase.effect[id].offset_x
    local offsetY = self._staticDatabase.effect[id].offset_y
    if offsetX == nil then
        offsetX = 0.0
    end
    if offsetY == nil then
        offsetY = 0.0
    end
    return offsetX, offsetY
end

function QStaticDatabase:getEffectRotationByID(id)
    if id == nil then return nil end

    local rotation = self._staticDatabase.effect[id].rotation
    if rotation == nil then
        rotation = 0.0
    end
    return rotation
end

function QStaticDatabase:getEffectIsFlipWithActorByID(id)
    if id == nil then return true end
    local is_flip_with_actor = self._staticDatabase.effect[id].is_flip_with_actor
    if is_flip_with_actor == nil then
        return true
    else 
        return is_flip_with_actor
    end
end

function QStaticDatabase:getEffectDummyByID(id)
    if id == nil then return nil end

    return self._staticDatabase.effect[id].dummy
end

function QStaticDatabase:getEffectIsLayOnTheGroundByID(id)
    if id == nil then return false end

    if self._staticDatabase.effect[id].is_lay_on_the_ground == true then
        return true
    else
        return false
    end
end

function QStaticDatabase:getEffectDelayByID(id)
    if id == nil then return nil end

    return self._staticDatabase.effect[id].delay
end

function QStaticDatabase:getEffectSoundIdById(id)
    if id == nil then return nil end

    return self._staticDatabase.effect[id].audio_id
end

function QStaticDatabase:getEffectSoundStopByID(id)
    if id == nil then return nil end

    return self._staticDatabase.effect[id].audio_stop
end

--鑾峰彇閿欒鐮�
function QStaticDatabase:getErrorCode(code)
    return self._staticDatabase.errorcode[code]
end

-- get dungeon hero config
function QStaticDatabase:getDungeonHeroByIndex(index)
    for _,value in pairs(self._staticDatabase.dungeon_hero) do
        if tonumber(value.id) == tonumber(index) then
            return value
        end
    end
    return nil
end

--根据竞技场排名获取相应的奖励
function QStaticDatabase:getAreanRewardByRank(rank)
  if rank == nil then return end
  if rank <= 10 then
    return self._staticDatabase.pvp_rank_reward[tostring(rank)]
  end
  local rankNums = table.nums(self._staticDatabase.pvp_rank_reward)
  
  for i = 1, table.nums(self._staticDatabase.pvp_rank_reward), 1 do
    if rank >= self._staticDatabase.pvp_rank_reward[tostring(i)].rank and (i + 1) > rankNums then
      return self._staticDatabase.pvp_rank_reward[tostring(rankNums)], self._staticDatabase.pvp_rank_reward[tostring(rankNums)].rank
    elseif rank >= self._staticDatabase.pvp_rank_reward[tostring(i)].rank and rank <= self._staticDatabase.pvp_rank_reward[tostring(i + 1)].rank then
      return self._staticDatabase.pvp_rank_reward[tostring(i)], self._staticDatabase.pvp_rank_reward[tostring(i)].rank, self._staticDatabase.pvp_rank_reward[tostring(i + 1)].rank
    end
  end
  return nil
end

function QStaticDatabase:getSunwellMap()
    return self._staticDatabase.sunwell_map
end

function QStaticDatabase:getSunwellAwardsByIndex(index)
    return self._staticDatabase.sunwell_reward[tostring(index)]
end

function QStaticDatabase:getAnnouncement(index)
    if index ~= nil then
        return self._staticDatabase.announcement[index]
    else
        return self._staticDatabase.announcement
    end
end

function QStaticDatabase:getVIP()
    return self._staticDatabase.vip
end

return QStaticDatabase