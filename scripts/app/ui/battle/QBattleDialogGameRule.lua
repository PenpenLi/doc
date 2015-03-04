
local QBattleDialog = import(".QBattleDialog")
local QBattleDialogGameRule = class(".QBattleDialogGameRule", QBattleDialog)

function QBattleDialogGameRule:ctor(ccbi, closeCallback)
	self._closeCallback = closeCallback
	QBattleDialogGameRule.super.ctor(self, ccbi)

	local ccbNode =  tolua.cast(self:getChildren():objectAtIndex(1), "CCNode")
	ccbNode:retain()
	ccbNode:removeFromParentAndCleanup(false)

	local ccbProxy = CCBProxy:create()
    local ccbOwner = {}
    local animationNode = CCBuilderReaderLoad("ccb/QBox/QDialog.ccbi", ccbProxy, ccbOwner)

    ccbOwner.dialogTarget:addChild(ccbNode)
    ccbNode:release()
    self:addChild(animationNode)

    self._animationManager = tolua.cast(animationNode:getUserObject(), "CCBAnimationManager")
    self._animationManager:runAnimationsForSequenceNamed("showDialogScale")
end

function QBattleDialogGameRule:close()
    self._animationManager:runAnimationsForSequenceNamed("hideDialogScale")

    local animationProxy = QCCBAnimationProxy:create()
    animationProxy:retain()
    animationProxy:connectAnimationEventSignal(self._animationManager, function(animationName)
        animationProxy:disconnectAnimationEventSignal()
        animationProxy:release()
        if self._closeCallback then
	    	self._closeCallback()
	    end
		QBattleDialogGameRule.super.close(self)
    end)
end

return QBattleDialogGameRule