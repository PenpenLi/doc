--
-- Author: wkwang
-- Date: 2014-09-10 15:57:39
--
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetOpenEffect = class("QUIWidgetOpenEffect", QUIWidget)

QUIWidgetOpenEffect.EFFECT_SCALE = "showDialogScale" --缩放进场

function QUIWidgetOpenEffect:ctor(options)
	local ccbFile = "ccb/QBox/QDialog.ccbi"
	local callbacks = {}
	QUIWidgetOpenEffect.super.ctor(self, ccbFile, callbacks, options)

    self._animationProxy = QCCBAnimationProxy:create()
    self._animationProxy:retain()
    self._animationManager = tolua.cast(self._ccbView:getUserObject(), "CCBAnimationManager")
    self._animationProxy:connectAnimationEventSignal(self._animationManager, handler(self, self._playOverHandler))

	self._play = false
end

function QUIWidgetOpenEffect:addView(node)
	self._ccbOwner.dialogTarget:addChild(node)
end

function QUIWidgetOpenEffect:play(node, callBack, effectName)
	if self._play then return end
	if effectName == nil then
		effectName = QUIWidgetOpenEffect.EFFECT_SCALE
	end
	self._play = true 
	self._callBack = callBack
	self._node = node
	self._ccbOwner.dialogTarget:addChild(node)
	self._animationManager:runAnimationsForSequenceNamed(effectName)
end

function QUIWidgetOpenEffect:_playOverHandler()
	self._animationProxy:disconnectAnimationEventSignal()
	self._animationProxy:release()
	self._animationProxy = nil

	if self._play == true then
		self._play = false
		if self._callBack ~= nil then
			self._callBack(self._node)
			self._callBack = nil
			self._node = nil
		end
	end
end

return QUIWidgetOpenEffect