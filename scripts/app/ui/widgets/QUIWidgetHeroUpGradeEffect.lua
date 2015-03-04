--
-- Author: wkwang
-- Date: 2014-09-03 20:18:18
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetHeroUpGradeEffect = class("QUIWidgetHeroUpGradeEffect", QUIWidget)

function QUIWidgetHeroUpGradeEffect:ctor(options)
	local ccbFile = "ccb/Widget_HeroUpEffect.ccbi"
	local callBacks = {
		}
	QUIWidgetHeroUpGradeEffect.super.ctor(self, ccbFile, callBacks, options)

	self._animationProxy = QCCBAnimationProxy:create()
    self._animationProxy:retain()
    self._animationManager = tolua.cast(self._ccbView:getUserObject(), "CCBAnimationManager")
    self._animationProxy:connectAnimationEventSignal(self._animationManager, function(name)
        self._animationProxy:disconnectAnimationEventSignal()
        self._animationProxy:release()
        self._animationProxy = nil
        self:setVisible(false)
    end)
    self:setVisible(false)
end

function QUIWidgetHeroUpGradeEffect:play()
	self:setVisible(true)
    self._animationManager:runAnimationsForSequenceNamed("state_play")
end

return QUIWidgetHeroUpGradeEffect