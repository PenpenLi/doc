--
-- Author: wkwang
-- Date: 2014-10-10 18:29:18
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetAnimationPlayer = class("QUIWidgetAnimationPlayer", QUIWidget)

function QUIWidgetAnimationPlayer:ctor(options)
	QUIWidgetAnimationPlayer.super.ctor(self,ccbFile,callBacks,options)
end

function QUIWidgetAnimationPlayer:playAnimation(ccbFile, playPreCall, playEndCall, isAutoDisappear)
	local proxy = CCBProxy:create()
    if self._ccbView ~= nil then
        self:disappear()
    end
    if isAutoDisappear == nil then
        isAutoDisappear = true
    end
    self.isAutoDisappear = isAutoDisappear
	self._ccbOwner = {}
    self._ccbView = CCBuilderReaderLoad(ccbFile, proxy, self._ccbOwner)
    self:addChild(self._ccbView)
    if playPreCall ~= nil then
    	playPreCall(self._ccbOwner,self._ccbView)
    end
    self._playEndCall = playEndCall
	self._animationProxy = QCCBAnimationProxy:create()
    self._animationProxy:retain()
    self._animationManager = tolua.cast(self._ccbView:getUserObject(), "CCBAnimationManager")
    self._animationProxy:connectAnimationEventSignal(self._animationManager, function(name)
        self._animationProxy:disconnectAnimationEventSignal()
        self._animationProxy:release()
        self._animationProxy = nil

        if self.isAutoDisappear == true then
            self:disappear()
        end
        if self._playEndCall ~= nil then
            self._playEndCall()
            self._playEndCall = nil
        end
    end)
end

function QUIWidgetAnimationPlayer:disappear()
	if self._ccbView ~= nil then
		self:removeChild(self._ccbView, true)
		self._ccbOwner = nil
		self._ccbView = nil
		self._animationProxy = nil
		self._animationManager = nil
	end
end

return QUIWidgetAnimationPlayer