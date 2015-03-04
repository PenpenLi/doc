
local QELoginScene = class("QELoginScene", function()
    return display.newScene("QELoginScene")
end)

local QESkeletonViewer = import(".QESkeletonViewer")

local textFieldWidth = 360
local textFieldHeight = 60
local textFieldOffsetX = 80
local textFieldOffsetY = 8
local loginButtonWidth = 150
local loginButtonHeight = 60

function QELoginScene:ctor(options)
	-- background
	self._root = CCLayerColor:create(ccc4(128, 128, 128, 255), display.width, display.height)
	self:addChild(self._root)

	-- address text field
	self._addressColorLayer = CCLayerColor:create(display.COLOR_WHITE_C4, textFieldWidth, textFieldHeight)
	self._root:addChild(self._addressColorLayer)
	self._addressColorLayer:setPosition(display.cx - textFieldWidth * 0.5 - textFieldOffsetX, display.cy + textFieldOffsetY)
	self._addressColorLayer:setOpacity(0)

	self._addressEditBox = ui.newEditBox( {
        image = "ui/none.png",
        listener = handler(self, QELoginScene.onAddressEdit),
        size = CCSize(textFieldWidth - 5, textFieldHeight)} )
	self._root:addChild(self._addressEditBox)
	self._addressEditBox:setFontColor(display.COLOR_MAGENTA)
	self._addressEditBox:setPosition(display.cx - textFieldOffsetX + 5, display.cy + textFieldHeight * 0.5)
	self._addressEditBox:setEnabled(false)
	self._addressEditBox:setText("127.0.0.1")

	-- connect menu
	self._menu = CCMenu:create();
	self._root:addChild(self._menu)
	self._menu:setPosition(0, 0)

	self._loginColorLayer = CCLayerColor:create(display.COLOR_ORANGE_C4, loginButtonWidth, loginButtonHeight)
	self._root:addChild(self._loginColorLayer)
	self._loginColorLayer:setPosition(display.cx + textFieldWidth * 0.3 + 20, display.cy + textFieldOffsetY)
	self._loginColorLayer:setOpacity(0)

	self._loginLabel = ui.newTTFLabel( {
		text = "Connect",
		font = global.font_monaco,
		size = 35,
		} )
	self._root:addChild(self._loginLabel)
	self._loginLabel:setPosition(display.cx + textFieldWidth * 0.5 + 22.5, display.cy + loginButtonHeight * 0.5 + 5)
	self._loginLabel:setOpacity(0)

	self._loginButton = ui.newTTFLabelMenuItem( {
		text = "Connect",
		font = global.font_monaco,
		size = 30,
		listener = handler(self, QELoginScene.onLogin),
		} )
	self._menu:addChild(self._loginButton)
	self._loginButton:setPosition(display.cx + textFieldWidth * 0.5 + 20, display.cy + loginButtonHeight * 0.5 + 5)
	self._loginButton:setEnabled(false)

	-- connect error info
	self._loginFaildInfo = ui.newTTFLabel( {
		text = "",
		font = global.font_monaco,
		size = 35,
		color = display.COLOR_GREEN,
		} )
	self._root:addChild(self._loginFaildInfo)
	self._loginFaildInfo:setPosition(display.cx, display.cy - 50)

	-- connect animation
	local ccbFile = "ccb/Widget_Loading.ccbi"
	local ccbOwner = {}
	local proxy = CCBProxy:create()
    self._loadingView = CCBuilderReaderLoad(ccbFile, proxy, ccbOwner)
    self._root:addChild(self._loadingView)
    self._loadingView:setPosition(display.cx, display.cy - 60)
    self._loadingView:setVisible(false)
end

function QELoginScene:onEnter()
	-- enter with fade in 
	local fadeInTime = 0.6
	self._addressColorLayer:runAction(CCFadeIn:create(fadeInTime))
	self._loginColorLayer:runAction(CCFadeIn:create(fadeInTime))
	self._loginLabel:runAction(CCFadeIn:create(fadeInTime))
	self._addressEditBox:runAction(CCFadeIn:create(fadeInTime))

	scheduler.performWithDelayGlobal(function()
        self._addressEditBox:setEnabled(true)
        self._loginButton:setEnabled(true)
    end, 1)
end

function QELoginScene:onExit()

end

function QELoginScene:onAddressEdit(editbox)
    
end

function QELoginScene:onLogin(tag)
	local host = self._addressEditBox:getText()
	if host == nil or string.len(host) == 0 then
		return
	end

	scheduler.performWithDelayGlobal(function()
		app.editor:connect(host, handler(self, self.onConnectCallBack))
    end, 0.6)

    self._loadingView:setVisible(true)
    self._addressEditBox:setEnabled(false)
    self._loginButton:setEnabled(false)
    self._loginFaildInfo:stopAllActions()
    self._loginFaildInfo:runAction(CCFadeOut:create(0))
end

function QELoginScene:onConnectCallBack(isSuccess)
	self._loginButton:setEnabled(true)
	self._addressEditBox:setEnabled(true)
	self._loadingView:setVisible(false)

	if isSuccess == true then
		app.editor:onConnect()
	else
		self._loginFaildInfo:stopAllActions()
		self._loginFaildInfo:setString("cannot connect server: " .. self._addressEditBox:getText())

		local arr = CCArray:create()
        arr:addObject(CCFadeIn:create(0.01))
        arr:addObject(CCDelayTime:create(2.5))
        arr:addObject(CCFadeOut:create(1.5))
        self._loginFaildInfo:runAction(CCSequence:create(arr))
	end
end

return QELoginScene