
local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetMailSheet = class(".QUIWidgetMailSheet", QUIWidget)

local QUIViewController = import("..QUIViewController")
local QNotificationCenter = import("...controllers.QNotificationCenter")
local QUIWidgetItemsBox = import("..widgets.QUIWidgetItemsBox")

QUIWidgetMailSheet.MAIL_EVENT_CLICK = "MAIL_EVENT_CLICK"

function QUIWidgetMailSheet:ctor(options)
	local ccbFile = "ccb/Widget_Email_sheet.ccbi"
	local callbacks = {
		{ccbCallbackName = "onTriggerClick", callback = handler(self, QUIWidgetMailSheet._onTriggerClick)}
    }
	QUIWidgetMailSheet.super.ctor(self, ccbFile, callbacks, options)

	self.mail = options["mail"]
	self._ccbOwner.title:setString(self.mail.title)
	self._ccbOwner.from:setString(self.mail.from or "")
	local date = os.date("*t", self.mail.publishTime/1000)
	self._ccbOwner.timestamp:setString(tostring(date.year) .. "-" .. tostring(date.month) .. "-" .. tostring(date.day))

	if self.mail.readed == true then
		self._ccbOwner.highlight:setVisible(false)
	end

	local mailIcon = QUIWidgetItemsBox.new()
    self._ccbOwner.thumbnail:addChild(mailIcon:getView())

    self._ccbOwner.node_icon:setVisible(false)
    self._ccbOwner.node_email_close:setVisible(false)
    self._ccbOwner.node_email_open:setVisible(false)
    self._ccbOwner.node_awards:setVisible(false)
    -- self._ccbOwner.node_money:setVisible(false)

    
    if self.mail.items == nil or self.mail.items[1] == nil then
    	self._ccbOwner.node_icon:setVisible(true)
        if self.mail.awards ~= nil and #self.mail.awards > 0 then
            local respath = remote.items:getURLForItem(self.mail.awards[1].type)
            if respath ~= nil then
                local texture = CCTextureCache:sharedTextureCache():addImage(respath)
                self._ccbOwner.node_awards:setTexture(texture)
                local size = texture:getContentSize()
                local rect = CCRectMake(0, 0, size.width, size.height)
                self._ccbOwner.node_awards:setTextureRect(rect)
            end
            self._ccbOwner.node_awards:setVisible(true)
        elseif self.mail.readed == true then
            self._ccbOwner.node_email_open:setVisible(true)
        elseif self.mail.readed == false then
            self._ccbOwner.node_email_close:setVisible(true)
        end
    else
        if #self.mail.items > 0 then
            mailIcon:setGoodsInfo(self.mail.items[1].itemId, ITEM_TYPE.ITEM , 0)
        end
    end

	self._btnEnable = true
end

function QUIWidgetMailSheet:onEnter()
end

function QUIWidgetMailSheet:onExit()
end

function QUIWidgetMailSheet:setBtnDisable()
	self._btnEnable = false
end

function QUIWidgetMailSheet:_onTriggerClick()
	if self._btnEnable == false then 
		self._btnEnable = true
		return
	end
    QNotificationCenter.sharedNotificationCenter():dispatchEvent({name = QUIWidgetMailSheet.MAIL_EVENT_CLICK, mail = self.mail})
end

return QUIWidgetMailSheet
