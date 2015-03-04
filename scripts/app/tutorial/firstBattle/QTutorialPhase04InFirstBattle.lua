
local QTutorialPhase = import("..QTutorialPhase")
local QTutorialPhase04InFirstBattle = class("QTutorialPhase04InFirstBattle", QTutorialPhase)

local QBaseActorView = import("...views.QBaseActorView")
local QUIWidgetBattleTutorialDialogue = import("...ui.widgets.QUIWidgetBattleTutorialDialogue")
local QUIWidgetTutorialHandTouch = import("...ui.widgets.QUIWidgetTutorialHandTouch")

-- 从英雄脚底显示出移动路径，手型动画从英雄头顶滑到路径的终点，显示“移动英雄”字样，直到用户操作后才消失
function QTutorialPhase04InFirstBattle:start()
	self._stage:enableTouch(handler(self, self._onTouch))

	-- self._dialogueLeft = QUIWidgetBattleTutorialDialogue.new({isLeftSide = true, text = "注意躲避伤害圈，快风骚地走位！", name = "督军杰克"})
 --    self._dialogueLeft:setActorImage("ui/orc_warlord.png")
 --    app.scene:addChild(self._dialogueLeft)

	self._hero = self._stage:getHeroByTag(self._stage.Tag_orc_warlord)
	local heroPosition = self._hero:getPosition_Stage()

    self._handTouch = QUIWidgetTutorialHandTouch.new()
    self._handTouch:setPosition(heroPosition.x - 3.5 * global.pixel_per_unit, heroPosition.y)
    app.scene:addChild(self._handTouch)
end

function QTutorialPhase04InFirstBattle:_onTouch(event)
    if event.name == "began" then
        return true
    elseif event.name == "ended" then
		local lineLength = 3.5 * global.pixel_per_unit
		local heroPosition = self._hero:getPosition_Stage()
		local targetPositionX = heroPosition.x - lineLength
		local targetPositionY = heroPosition.y
		if math.abs(event.x - targetPositionX) < 64 and math.abs(event.y - targetPositionY) < 64 and self:oneTimeCheck() then
            app.battle:resume()
            app.grid:moveActorTo(self._hero, {x = targetPositionX, y = targetPositionY})
            scheduler.performWithDelayGlobal(function()
                self._stage:disableTouch()
                -- self._dialogueLeft:removeFromParent()
                self._handTouch:removeFromParent()
            end, 0)
            scheduler.performWithDelayGlobal(function()
                local view = app.scene:getActorViewFromModel(self._hero)
                if view ~= nil then
                    view:setDirection(QBaseActorView.DIRECTION_RIGHT)
                end
                self:finished()
            end, 1.3)

            _G["_tutorial_allow_trap_play"] = false
		end
        self._isBeginVaild = false
    end
end

return QTutorialPhase04InFirstBattle