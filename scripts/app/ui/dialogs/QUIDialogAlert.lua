--
-- Author: wkwang
-- Date: 2014-07-17 14:08:11
--
local QUIDialog = import("..dialogs.QUIDialog")
local QUIDialogAlert = class("QUIDialogAlert", QUIDialog)

local QNavigationController = import("...controllers.QNavigationController")

function QUIDialogAlert:ctor(options)
	assert(options ~= nil, "alert dialog options is nil !")
 	local ccbFile = "ccb/Dialog_AlertSystem.ccbi"
    local callBacks = {
        {ccbCallbackName = "onTriggerClose", callback = handler(self, QUIDialogAlert._onTriggerClose)},
        {ccbCallbackName = "onTriggerConfirm", callback = handler(self, QUIDialogAlert._onTriggerConfirm)},
    }
    QUIDialogAlert.super.ctor(self, ccbFile, callBacks, options)

    self.isAnimation = true

    self._wordsSize = 40/3 --一个英文字母占的宽度
    self._chinese = 24 --一个中文字符占的宽度
    self._height = 25 --一个中文字符占的宽度
    self._TFWidth = self._ccbOwner.node_tf_bg:getContentSize().width * self._ccbOwner.node_tf_bg:getScaleX() --文本框的最大宽度

    self._closeCallBack = options.callBack
    if options.comfirmBack then
    	self._comfirmBack = options.comfirmBack
    else
    	self._comfirmBack = nil
    end

    if options.confirmText then
    	self._ccbOwner.confirmText:setString(options.confirmText)
    end

    if options.content then
    	self._content = options.content
    	self._ccbOwner.tf_content:setString(q.autoWrap(self._content, self._chinese, self._wordsSize, self._TFWidth))
    	self:_autoSizeTFContent()
    end

    if options.title then
    	self._title = options.title
    	self._ccbOwner.tf_title:setString(self._title)
    end

    if (self._comfirmBack == nil and self._closeCallBack == nil) or (self._comfirmBack == nil and self._closeCallBack ~= nil) or (self._comfirmBack ~= nil and self._closeCallBack == nil) then
    	self._ccbOwner.btn_ok:setPositionX(0)
    	self._ccbOwner.btn_cancel:setVisible(false)
    end

    if options.ok_only then
	    self._ccbOwner.btn_ok:setVisible(true)
	    self._ccbOwner.btn_cancel:setVisible(false)
	    self._ccbOwner.btn_ok:setPositionX(self._ccbOwner.btn_ok:getPositionX() - 100)
	end
end

function QUIDialogAlert:_convertWords(input)
  	if string.len(input) == 0 then return "" end
		str = ""
		i = 1
		len = 0
		while true do 
	        c = string.sub(input,i,i)
	        b = string.byte(c)
	        if b > 128 then
	          	str = str .. (string.sub(input,i,i+2))
	          	len = len + self._chinese
	          	i = i + 3
	        else
	          	if b ~= 32 then
	          		str = str .. c
	          	end
	          	len = len + self._wordsSize
	          	i = i + 1
	      	end
	      	if i > #input then
	            break
	      	end
	      	if len >= self._TFWidth then
	      		str = str .. "\n"
	      		len = 0
	      	end
	 end
	 return str
end

-- 自动居中文本框
function QUIDialogAlert:_autoSizeTFContent()
	local tfSize = self._ccbOwner.tf_content:getContentSize()
	self._ccbOwner.tf_content:setPositionX(- tfSize.width/2)
end

function QUIDialogAlert:_onTriggerClose()
	self._type = "close"
	app.sound:playSound("common_cancel")
	self:close()
end

function QUIDialogAlert:_onTriggerConfirm()
	self._type = "confrim"
	self:close()
end

function QUIDialogAlert:_backClickHandler()
	local options = self:getOptions()
	if options.canBackClick ~= false then
    	self:close()
    end
end

function QUIDialogAlert:close()
	self:playEffectOut()
end

function QUIDialogAlert:viewAnimationOutHandler()
	local options = self:getOptions()
	if options.controller ~= nil then
		options.controller:popViewController(QNavigationController.POP_TOP_CONTROLLER)
	end
	if self._closeCallBack ~= nil then
		self._closeCallBack()
	end
	if self._type == "confrim" then
		if self._comfirmBack ~= nil then
			self._comfirmBack()
		end
	end
end

return QUIDialogAlert