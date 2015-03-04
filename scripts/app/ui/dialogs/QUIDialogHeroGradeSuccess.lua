--
-- Author: wkwang
-- Date: 2014-08-28 20:34:54
--
local QUIDialog = import(".QUIDialog")
local QUIDialogHeroGradeSuccess = class("QUIDialogHeroGradeSuccess", QUIDialog)

local QStaticDatabase = import("...controllers.QStaticDatabase")
local QUIWidgetHeroInformation = import("..widgets.QUIWidgetHeroInformation")
local QUIWidgetHeroInformationStar = import("..widgets.QUIWidgetHeroInformationStar")
local QHeroModel = import("...models.QHeroModel")
local QNavigationController = import("...controllers.QNavigationController")
local QUIViewController = import("..QUIViewController")

function QUIDialogHeroGradeSuccess:ctor(options)

	local ccbFile = "ccb/Dialog_HeroGradeSuccess.ccbi"
	local callBacks = {
						{ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogHeroGradeSuccess._onTriggerConfirm)}
					}
    QUIDialogHeroGradeSuccess.super.ctor(self,ccbFile,callBacks,options)

    if options == nil or options.hero == nil then
    	return 
    end
    self._hero = options.hero
    self._newHero = clone(self._hero)
    self._newHero.grade = self._newHero.grade + 1

	local heroModel = QHeroModel.new(self._hero)
	local heroNewModel = QHeroModel.new(self._newHero)

    self._ccbOwner.tf_hp:setString(string.format("%.1f",heroModel:getMaxHp()))
    self._ccbOwner.tf_hp_new:setString(string.format("%.1f",heroNewModel:getMaxHp()))
    self._ccbOwner.tf_attack:setString(string.format("%.1f",heroModel:getMaxAttack()))
    self._ccbOwner.tf_attack_new:setString(string.format("%.1f",heroNewModel:getMaxAttack()))
    
    self._informationStar = QUIWidgetHeroInformationStar.new()
    self._informationStar:showStar(self._hero.grade)
    self._ccbOwner.node_star:addChild(self._informationStar:getView())

    self._information = QUIWidgetHeroInformation.new(self._hero.actorId)
    self._information:setBattleForceVisible(false)
    self._ccbOwner.node_avatar:addChild(self._information:getView())
    local characherConfig = QStaticDatabase:sharedDatabase():getCharacterDisplayByActorID(self._hero.actorId)
    if characherConfig ~= nil then
        self._information:setAvatar(self._hero.actorId, 1.287)
    end

	--技能
    local characterInfo = QStaticDatabase:sharedDatabase():getCharacterByID(self._hero.actorId)
    local gradeInfo = QStaticDatabase:sharedDatabase():getHeroGradeSkill(characterInfo.talent)
    self._gradeSkill = nil
    if gradeInfo ~= nil then
        for _,gradeConfig in pairs(gradeInfo) do
            if gradeConfig.grade_level == self._hero.grade+1 then
            	local skill = QStaticDatabase:sharedDatabase():getSkillsByNameLevel(gradeConfig.skill,1)
            	if skill ~= nil then
                	self._gradeSkill = skill.id
                end
                break
            end
        end
    end

end

function QUIDialogHeroGradeSuccess:autoLayout(node1,node2,node3)
	local gap = 10
    local posX = node1:getPositionX() + node1:getContentSize().width + gap
    node2:setPositionX(posX)
    posX = posX + node2:getContentSize().width + gap
    node3:setPositionX(posX)
end

function QUIDialogHeroGradeSuccess:_onTriggerConfirm()
    app:getNavigationMidLayerController():popViewController(QNavigationController.POP_TOP_CONTROLLER)
    if self._gradeSkill ~= nil then
    	-- app:getNavigationMidLayerController():pushViewController({uiType = QUIViewController.TYPE_DIALOG, uiClass = "QUIDialogHeroSkillUnlock",
    	--  options = {skill=self._gradeSkill, hero = self._hero}})
    end
end

function QUIDialogHeroGradeSuccess:_backClickHandler()
	self:_onTriggerConfirm()
end

return QUIDialogHeroGradeSuccess