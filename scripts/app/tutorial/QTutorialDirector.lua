
local QTutorialDirector = class("QTutorialDirector")

local QTutorialStageFirstBattle = import(".firstBattle.QTutorialStageFirstBattle")
local QTutorialStageTeamAndDungeon = import(".team&dungeon.QTutorialStageTeamAndDungeon")
local QTutorialStageSkill = import(".skill.QTutorialStageSkill")
local QTutorStageBreakthrough = import(".breakthrough.QTutorStageBreakthrough")
local QTutorialStageTreasure = import(".Treasure.QTutorialStageTreasure")
local QTutorialStageEquipmentAndSkill = import(".equipment&skill.QTutorialStageEquipmentAndSkill")
local QTutorialStageIntensify = import(".Intensify.QTutorialStageIntensify")
local QTutorialStageEliteCopy = import(".eliteCopy.QTutorialStageEliteCopy")
local QTutorialArenaAddName = import(".addName.QTutorialStageArenaAddName")
local QStaticDatabase = import("...controllers.QStaticDatabase")

QTutorialDirector.Stage_1_FirstBattle = 0 		 	    -- 新手战斗
QTutorialDirector.Stage_2_Treasure = 1              -- 宝箱引导
QTutorialDirector.Stage_3_TeamAndDungeon = 2 		    -- 阵容和副本引导
QTutorialDirector.Stage_4_Equipment = 3             -- 英雄装备引导
QTutorialDirector.Stage_5_Skill = 4                 -- 英雄技能引导
QTutorialDirector.Stage_6_Intensify = 5             -- 英雄升级引导
QTutorialDirector.Stage_7_Breakthrough = 6          -- 英雄突破引导
QTutorialDirector.Stage_8_NewHero = 7               -- 新英雄引导
QTutorialDirector.Stage_9_TeamBox = 8               -- 战队解锁引导
QTutorialDirector.Stage_10_ArenaAddName = 9         -- 竞技场起名引导
QTutorialDirector.Guide_Start = 0                   -- 引导开始
QTutorialDirector.Guide_End = 1                     -- 引导结束
QTutorialDirector.FORCED_GUIDE_STOP = 3

function QTutorialDirector:ctor()
  self._runingStage = nil
  self._stage = {forcedGuide = 0, intencifyGuide = 0, breakthroughGuide = 0, skillGuide = 0, guideEnd = 0, newHeroGuide = 0, temaBoxGuide = 0}
end

function QTutorialDirector:getStage()
  return self._stage
end

function QTutorialDirector:setStage(stage)
  self._stage = stage
  if self._stage.forcedGuide == 4 and self._stage.intencifyGuide == 1 and self._stage.breakthroughGuide == 1 and 
     self._stage.skillGuide ==1 then
     
    self._stage.guideEnd = 1
    self:setFlag()
  end
end

function QTutorialDirector:setFlag()
  local _value = self._stage.breakthroughGuide..";"..self._stage.forcedGuide..";"..self._stage.guideEnd..";"..self._stage.intencifyGuide..";"..self._stage.newHeroGuide..";"..self._stage.skillGuide..";"..self._stage.temaBoxGuide
  remote.flag:set(remote.flag.FLAG_TUTORIAL_STAGE, _value)
end

function QTutorialDirector:initStage(stage)
  if stage == nil then
    return
  end
  local _stage = string.split(stage, ";")
  self._stage.breakthroughGuide = tonumber(_stage[1]) 
  self._stage.forcedGuide = tonumber(_stage[2]) 
  self._stage.guideEnd = tonumber(_stage[3])
  self._stage.intencifyGuide = tonumber(_stage[4])
  self._stage.newHeroGuide = tonumber(_stage[5]) 
  self._stage.skillGuide = tonumber(_stage[6])
  self._stage.temaBoxGuide = tonumber(_stage[7])
end

function QTutorialDirector:isTutorialFinished()
  if SKIP_TUTORIAL == true then
    return true
  end
  return self._stage.guideEnd > 0
end

function QTutorialDirector:canStartTutorial(stage)
  if stage == nil then
    return false
  end

  return self._stage.guideEnd < 1
end

function QTutorialDirector:startTutorial(stage)
  if stage == nil then
    return
  end

  if self._runingStage ~= nil then
    return
  end

--  if ONLY_BATTLE_TUTORIAL == true then
--    if stage == QTutorialDirector.Stage_1_FirstBattle then
--      self._runingStage = QTutorialStageFirstBattle.new()
--    else
--      return
--    end
--  else
    		if stage == QTutorialDirector.Stage_1_FirstBattle then
    			self._runingStage = QTutorialStageFirstBattle.new()
    		elseif stage == QTutorialDirector.Stage_2_Treasure then
            self._runingStage = QTutorialStageTreasure.new()
    		elseif stage == QTutorialDirector.Stage_3_TeamAndDungeon then
    			self._runingStage = QTutorialStageTeamAndDungeon.new()
    		elseif stage == QTutorialDirector.Stage_4_Equipment then
    		  self._runingStage = QTutorialStageEquipmentAndSkill.new()
    		elseif stage == QTutorialDirector.Stage_5_Skill then
    			self._runingStage = QTutorialStageSkill.new()
    		elseif stage == QTutorialDirector.Stage_6_Intensify then
    	    self._runingStage = QTutorialStageIntensify.new()
    		elseif stage == QTutorialDirector.Stage_7_Breakthrough then
    			self._runingStage = QTutorStageBreakthrough.new()
        elseif stage == QTutorialDirector.Stage_9_TeamBox then
       	  self._runingStage = QTutorialStageEliteCopy.new()
        elseif stage == QTutorialDirector.Stage_10_ArenaAddName then
          self._runingStage = QTutorialArenaAddName.new()
    		else
    			return
    		end
--  end

  if self._runingStage == nil then
    return
  end

  scheduler.performWithDelayGlobal(function()
    self._runingStage:start()
    self._frameHandle = scheduler.scheduleUpdateGlobal(handler(self, QTutorialDirector._onFrame))
  end, 0)

end

function QTutorialDirector:_onFrame(dt)
  if self._runingStage:isStageFinished() == true then
    self._runingStage:ended()
    scheduler.unscheduleGlobal(self._frameHandle)
    self._frameHandle = nil
    self._runingStage = nil
    return
  end

  self._runingStage:visit()
end

function QTutorialDirector:isInTutorial()
  return (self._runingStage ~= nil)
end

return QTutorialDirector
