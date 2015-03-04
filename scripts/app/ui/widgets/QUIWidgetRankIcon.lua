--
-- Author: wkwang
-- 军衔滚动图标类
-- Date: 2014-07-02 17:52:17
--
local QUIWidget = import(".QUIWidget")
local QUIWidgetRankIcon = class("QUIWidgetRankIcon", QUIWidget)

function QUIWidgetRankIcon:ctor(options)
	local ccbFile = "ccb/Widget_MilitaryRankInformation.ccbi"
	local callBacks = {
			{ccbCallbackName = "onTriggerClickHandler", callback = handler(self, QUIWidgetRankIcon._onTriggerClickHandler)},
		}
	QUIWidgetRankIcon.super.ctor(self,ccbFile,callBacks,options)

	if options ~= nil and options.config ~= nil then
		self._config = options.config
		self:initConfig(options.config)
	end
end

function QUIWidgetRankIcon:selected(b)
	self._ccbOwner.selectEffect:setVisible(b)
end

function QUIWidgetRankIcon:getConfig()
	return self._config
end

function QUIWidgetRankIcon:initConfig(config)
	self._ccbOwner.tf_name:setString(config.code..config.name)
    CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("ui/MilitaryRank.plist")
    printf(config.code..".png")
    local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(config.code..".png")
    if spriteFrame ~= nil then
    	self._ccbOwner.node_icon:setDisplayFrame(spriteFrame)
    end
end

function QUIWidgetRankIcon:getHeight()
	return self._ccbOwner.node_kuang:getContentSize().height
end

function QUIWidgetRankIcon:_onTriggerClickHandler()

end

return QUIWidgetRankIcon