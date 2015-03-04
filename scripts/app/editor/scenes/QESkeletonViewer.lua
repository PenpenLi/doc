
local QESkeletonViewer = class("QESkeletonViewer", function()
    return display.newScene("QESkeletonViewer")
end)

local QEBattleViewer = import(".QEBattleViewer")

QESkeletonViewer.ACTOR_MODE = 1
QESkeletonViewer.EFFECT_MODE = 2
QESkeletonViewer.EDIT_MODE = 3

QESkeletonViewer.EFFECT_EDIT_MODE = 1
QESkeletonViewer.EFFECT_PLAY_MODE = 2

QESkeletonViewer.EFFECT_FRAME_PLAY = 1
QESkeletonViewer.EFFECT_CONTINUE_PLAY = 2

function QESkeletonViewer:ctor(options)
	-- background
	self:addChild(CCLayerColor:create(ccc4(128, 128, 128, 255), display.width, display.height))

	-- coordinate axis
	self._axisNode = CCNode:create()
	self:addChild(self._axisNode)
	local horizontalLine = CCDrawNode:create()
	horizontalLine:drawLine({-display.cx, 0}, {display.cx, 0})
	self._axisNode:addChild(horizontalLine)
	local verticalLine = CCDrawNode:create()
	verticalLine:drawLine({0, -display.cy}, {0, display.height})
	self._axisNode:addChild(verticalLine)

	self._skeletonRoot = CCNode:create()
	self:addChild(self._skeletonRoot)
	self._skeletonRoot:setScale(UI_DESIGN_WIDTH / BATTLE_SCREEN_WIDTH)

	self._infomationNode = CCNode:create()
	self:addChild(self._infomationNode)
	self._infomationNode:setPosition(0, display.height)

	self._menu = CCMenu:create()
	self:addChild(self._menu)
	self._menu:setPosition(0, display.height)
end

function QESkeletonViewer:cleanup()
	if self._frameUpdateId ~= nil then
		scheduler.unscheduleGlobal(self._frameUpdateId)
		self._frameUpdateId = nil
	end

	self._skeletonRoot:removeAllChildren()
	self._skeleton = nil
	self._frontEffect = nil
	self._backEffect = nil

	self._infomationNode:removeAllChildren();
	self._menu:removeAllChildren();
	self._currentAnimation = nil
end

function QESkeletonViewer:onReceiveData(message)
	if message == nil then
		return;
	end

	self._message = message

	self:cleanup()

	if self._message.message == "display_actor" then
		self:onDisplayActor()
	elseif self._message.message == "display_effect" then
		self:onDisplayEffect()
	elseif self._message.message == "edit_effect" then
		self:onEditEffect()
	end
end

-- actor display

function QESkeletonViewer:onDisplayBoneClicked()
	if self._isDisplayBone == true then
		self._boneCheckMenu:setString("No")
		self._skeleton:displayBones(false)
		self._isDisplayBone = false
	else
		self._boneCheckMenu:setString("Yes")
		self._skeleton:displayBones(true)
		self._isDisplayBone = true
	end
end

function QESkeletonViewer:onDisplayDummyClicked()
	if self._isDisplayDummy == true then
		self._dummyCheckMenu:setString("No")
		for _, label in ipairs(self._dummyLabels) do
			label:setVisible(false)
		end
		self._isDisplayDummy = false
	else
		self._dummyCheckMenu:setString("Yes")
		for _, label in ipairs(self._dummyLabels) do
			label:setVisible(true)
		end
		self._isDisplayDummy = true
	end
end

function QESkeletonViewer:onDisplayFreeDummyClicked()
	if self._isDisplayFreeDummy == true then
		self._freeDummyCheckMenu:setString("No")
		for _, label in ipairs(self._freeDummyLabels) do
			label:setVisible(false)
		end
		self._isDisplayFreeDummy = false
	else
		self._freeDummyCheckMenu:setString("Yes")
		for _, label in ipairs(self._freeDummyLabels) do
			label:setVisible(true)
		end
		self._isDisplayFreeDummy = true
	end
end

function QESkeletonViewer:onDisplayRectClicked()
	if self._isDisplayRect == true then
		self._rectCheckMenu:setString("No")
		self._boundingBox:setVisible(false)
		self._isDisplayRect = false
	else
		self._rectCheckMenu:setString("Yes")
		self._boundingBox:setVisible(true)
		self._isDisplayRect = true
	end
end

function QESkeletonViewer:onLoopClicked()
	if self._isLoopAnimation == true then
		self._loopCheckMenu:setString("No")
		self._isLoopAnimation = false
	else
		self._loopCheckMenu:setString("Yes")
		self._isLoopAnimation = true
	end

	if self._currentAnimation ~= nil then
		self._skeleton:resetActorWithAnimation(ANIMATION.STAND, false)
		self._skeleton:playAnimation(self._currentAnimation, self._isLoopAnimation)
	end
end

function QESkeletonViewer:onScaleIncreaseClicked()
	self._currentScale = self._currentScale + 0.1
	self._skeleton:setSkeletonScaleX(self._currentScale)
	self._skeleton:setSkeletonScaleY(self._currentScale)
	self._boundingBox:setScale(self._currentScale)
	self._scaleNumberLabel:setString(string.format("%.1f", self._currentScale))
end

function QESkeletonViewer:onScaleDecreaseClicked()
	self._currentScale = self._currentScale - 0.1
	self._skeleton:setSkeletonScaleX(self._currentScale)
	self._skeleton:setSkeletonScaleY(self._currentScale)
	self._boundingBox:setScale(self._currentScale)
	self._scaleNumberLabel:setString(string.format("%.1f", self._currentScale))
end

function QESkeletonViewer:onSpeedIncreaseClicked()
	self._currentSpeed = self._currentSpeed + 0.1
	self._skeleton:setAnimationScale(self._currentSpeed)
	self._speedNumberLabel:setString(string.format("%.1f", self._currentSpeed))
end

function QESkeletonViewer:onSpeedDecreaseClicked()
	self._currentSpeed = self._currentSpeed - 0.1
	if self._currentSpeed < 0 then
		self._currentSpeed = 0
	end
	self._skeleton:setAnimationScale(self._currentSpeed)
	self._speedNumberLabel:setString(string.format("%.1f", self._currentSpeed))
end

function QESkeletonViewer:onAnimationClicked(tag)
	local name = self._animationNames[tag]
	if name ~= nil and self._skeleton ~= nil then
		self._skeleton:resetActorWithAnimation(ANIMATION.STAND, false)
		self._skeleton:playAnimation(name, self._isLoopAnimation)
		self._currentAnimation = name
	end
end

function QESkeletonViewer:onHitMeClicked()
	if self._skeleton ~= nil and self._skeleton:isHitAnimationPlaying() == false then
		self._skeleton:playHitAnimation(ANIMATION.HIT)
	end
end

function QESkeletonViewer:onDisplayActor()
	self._axisNode:setPosition(display.cx, display.cy * 0.5)
	self._skeletonRoot:setPosition(display.cx, display.cy * 0.5)

	local filePath = self._message.file_path
	if filePath ~= nil and string.len(filePath) > 0 then
		-- create skeleton
		local startIndex, endIndex = string.find(filePath, ".json")
		local fileName = string.sub(filePath, 1, startIndex - 1)
		self._skeleton = QSkeletonActor:create(fileName)
		self._skeletonRoot:addChild(self._skeleton)
		self._skeleton:playAnimation(ANIMATION.STAND, true)
		self._currentAnimation = ANIMATION.STAND

		-- change weapon
		if self._message.weapon_file ~= nil and string.len(self._message.weapon_file) > 0 then
			local parentBone = self._skeleton:getParentBoneName(DUMMY.WEAPON)
        	self._skeleton:replaceSlotWithFile(self._message.weapon_file, parentBone, ROOT_BONE, EFFECT_ANIMATION)
		end

		-- attach dummy lable
		self._dummyLabels = {}
		self._freeDummyLabels = {}
		for dummyKey, dummyName in pairs(DUMMY) do
			if dummyName == DUMMY.TOP or dummyName == DUMMY.CENTER or dummyName == DUMMY.BOTTOM then
				if self._message.actor_height > 0 then
					local node = CCNode:create()
					local label = ui.newTTFLabel( {
						text = dummyName,
						font = global.font_monaco,
						color = display.COLOR_GREEN,
						size = 20 } )
					node:addChild(label)
					self._skeleton:attachNodeToBone(nil, node)
					label:setVisible(false)
					table.insert(self._freeDummyLabels, label)
					if dummyName == DUMMY.TOP then
						label:setPosition(0, self._message.actor_height)
					elseif dummyName == DUMMY.CENTER then
						label:setPosition(0, self._message.actor_height * 0.5)
					end
				end
			else
				if self._skeleton:isBoneExist(dummyName) == true then
					local label = ui.newTTFLabel( {
						text = dummyName,
						font = global.font_monaco,
						size = 20 } )
					self._skeleton:attachNodeToBone(dummyName, label)
					label:setVisible(false)
					table.insert(self._dummyLabels, label)
				end
			end
		end

		-- bounding box
		self._boundingBox = CCNode:create()
		self._skeleton:addChild(self._boundingBox)
		self._boundingBox:setScale(self._message.actor_scale)
		self._boundingBox:setVisible(false)
		if self._message.actor_width > 0 and self._message.actor_height > 0 then
			local displayRect = true
			local displayCoreRect = true

			if displayRect == true then
				local width = self._message.actor_width
				local height = self._message.actor_height
				local scale = self._message.actor_scale
				local rect = CCRectMake(-width * 0.5, 0, width, height)
		        rect.origin.x = rect.origin.x
		        rect.size.width = rect.size.width
		        rect.size.height = rect.size.height
		        local vertices = {}
		        table.insert(vertices, {rect.origin.x, rect.origin.y})
		        table.insert(vertices, {rect.origin.x, rect.origin.y + rect.size.height})
		        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y + rect.size.height})
		        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y})
		        local param = {
		            fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
		            borderWidth = 1,
		            borderColor = ccc4f(1.0, 0.0, 0.0, 1.0)
		        }
		        local drawNode = CCDrawNode:create()
		        drawNode:clear()
		        drawNode:drawPolygon(vertices, param) -- red color
		        self._boundingBox:addChild(drawNode)
			end
			
			if displayCoreRect == true then
				local width = self._message.actor_width
				local height = self._message.actor_height
				local scale = self._message.actor_scale * 0.8
				local rect = CCRectMake(-width * 0.5, 0, width, height)
		        rect.origin.x = rect.origin.x * scale
		        rect.size.width = rect.size.width * scale
		        rect.size.height = rect.size.height * scale
		        local vertices = {}
		        table.insert(vertices, {rect.origin.x, rect.origin.y})
		        table.insert(vertices, {rect.origin.x, rect.origin.y + rect.size.height})
		        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y + rect.size.height})
		        table.insert(vertices, {rect.origin.x + rect.size.width, rect.origin.y})
		        local param = {
		            fillColor = ccc4f(0.0, 0.0, 0.0, 0.0),
		            borderWidth = 1,
		            borderColor = ccc4f(1.0, 1.0, 0.0, 1.0)
		        }
		        local drawNode = CCDrawNode:create()
		        drawNode:clear()
		        drawNode:drawPolygon(vertices, param) -- yellow color
		        self._boundingBox:addChild(drawNode)
			end
		end

		-- button and lable at left top
		local positionX = 10 
		local positionY = -20
		local deltaX = 200

		self._nameLabel = ui.newTTFLabel( {
			text = self._message.actor_name or "unknow name",
			font = global.font_monaco,
			color = display.COLOR_ORANGE,
			size = 25 } )
		self._nameLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._nameLabel)
		self._nameLabel:setPosition(positionX, positionY)
		positionY = positionY - 25

		self._boneLabel = ui.newTTFLabel( {
			text = "bone",
			font = global.font_monaco,
			size = 25 } )
		self._boneLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._boneLabel)
		self._boneLabel:setPosition(positionX, positionY)

		self._boneCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onDisplayBoneClicked),
			text = "No",
			font = global.font_monaco,
			size = 25 } )
		self._boneCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._boneCheckMenu)
		self._boneCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayBone = false
		positionY = positionY - 25

		self._dummyLabel = ui.newTTFLabel( {
			text = "dummy",
			font = global.font_monaco,
			size = 25 } )
		self._dummyLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._dummyLabel)
		self._dummyLabel:setPosition(positionX, positionY)

		self._dummyCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onDisplayDummyClicked),
			text = "No",
			font = global.font_monaco,
			size = 25 } )
		self._dummyCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._dummyCheckMenu)
		self._dummyCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayDummy = false
		positionY = positionY - 25

		self._freeDummyLabel = ui.newTTFLabel( {
			text = "free dummy",
			font = global.font_monaco,
			size = 25 } )
		self._freeDummyLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._freeDummyLabel)
		self._freeDummyLabel:setPosition(positionX, positionY)

		self._freeDummyCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onDisplayFreeDummyClicked),
			text = "No",
			font = global.font_monaco,
			size = 25 } )
		self._freeDummyCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._freeDummyCheckMenu)
		self._freeDummyCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayFreeDummy = false
		positionY = positionY - 25

		self._rectLabel = ui.newTTFLabel( {
			text = "bounding box",
			font = global.font_monaco,
			size = 25 } )
		self._rectLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._rectLabel)
		self._rectLabel:setPosition(positionX, positionY)

		self._rectCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onDisplayRectClicked),
			text = "No",
			font = global.font_monaco,
			size = 25 } )
		self._rectCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._rectCheckMenu)
		self._rectCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayRect = false
		positionY = positionY - 25

		self._loopLabel = ui.newTTFLabel( {
			text = "loop",
			font = global.font_monaco,
			size = 25 } )
		self._loopLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._loopLabel)
		self._loopLabel:setPosition(positionX, positionY)

		self._loopCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onLoopClicked),
			text = "Yes",
			font = global.font_monaco,
			size = 25 } )
		self._loopCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._loopCheckMenu)
		self._loopCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isLoopAnimation = true
		positionY = positionY - 25

		self._scaleLabel = ui.newTTFLabel( {
			text = "scale",
			font = global.font_monaco,
			size = 25 } )
		self._scaleLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._scaleLabel)
		self._scaleLabel:setPosition(positionX, positionY)

		self._scaleDecreaseMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onScaleDecreaseClicked),
			text = "<",
			font = global.font_monaco,
			size = 25 } )
		self._scaleDecreaseMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._scaleDecreaseMenu)
		self._scaleDecreaseMenu:setPosition(positionX + deltaX, positionY)

		self._currentScale = self._message.actor_scale
		self._skeleton:setSkeletonScaleX(self._currentScale)
		self._skeleton:setSkeletonScaleY(self._currentScale)
		self._scaleNumberLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._currentScale),
			font = global.font_monaco,
			size = 25 } )
		self._scaleNumberLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._scaleNumberLabel)
		self._scaleNumberLabel:setPosition(positionX + deltaX + 30, positionY)

		self._scaleIncreaseMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onScaleIncreaseClicked),
			text = ">",
			font = global.font_monaco,
			size = 25 } )
		self._scaleIncreaseMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._scaleIncreaseMenu)
		self._scaleIncreaseMenu:setPosition(positionX + deltaX + 80, positionY)
		positionY = positionY - 25

		self._speedLabel = ui.newTTFLabel( {
			text = "speed",
			font = global.font_monaco,
			size = 25 } )
		self._speedLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._speedLabel)
		self._speedLabel:setPosition(positionX, positionY)

		self._speedDecreaseMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onSpeedDecreaseClicked),
			text = "<",
			font = global.font_monaco,
			size = 25 } )
		self._speedDecreaseMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._speedDecreaseMenu)
		self._speedDecreaseMenu:setPosition(positionX + deltaX, positionY)

		self._currentSpeed = 1.0
		self._speedNumberLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._currentSpeed),
			font = global.font_monaco,
			size = 25 } )
		self._speedNumberLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._speedNumberLabel)
		self._speedNumberLabel:setPosition(positionX + deltaX + 30, positionY)

		self._speedIncreaseMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onSpeedIncreaseClicked),
			text = ">",
			font = global.font_monaco,
			size = 25 } )
		self._speedIncreaseMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._speedIncreaseMenu)
		self._speedIncreaseMenu:setPosition(positionX + deltaX + 80, positionY)
		positionY = positionY - 40

		self._animationLabel = ui.newTTFLabel( {
			text = "animations:",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 25 } )
		self._animationLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._animationLabel)
		self._animationLabel:setPosition(positionX, positionY)

		self._hitMeMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onHitMeClicked),
			text = "Hit Me",
			font = global.font_monaco,
			size = 25 } )
		self._hitMeMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._hitMeMenu)
		self._hitMeMenu:setPosition(positionX + deltaX, positionY)

		positionY = positionY - 25

		local animationNames = self._skeleton:getAllAnimationName()
		local animationCount = animationNames:count()
		self._animationNames = {}
		for i = 1, animationCount do
			local animationName = tolua.cast(animationNames:objectAtIndex(i - 1), "CCString")
			local animationText = animationName:getCString()
			local menuItem = ui.newTTFLabelMenuItem( {
				listener = handler(self, QESkeletonViewer.onAnimationClicked),
				text = animationText,
				font = global.font_monaco,
				size = 25,
				color = display.COLOR_GREEN,
				tag = i } )
			menuItem:setAnchorPoint(ccp(0.0, 0.5))
			self._menu:addChild(menuItem)
			menuItem:setPosition(positionX, positionY)
			table.insert(self._animationNames, animationText)
			positionY = positionY - 25
		end

	end

	self._currentMode = QESkeletonViewer.ACTOR_MODE
end

-- effect display

function QESkeletonViewer:onDisplayEffect()
	self._axisNode:setPosition(display.cx, display.cy)
	self._skeletonRoot:setPosition(display.cx, display.cy)

	local frontFile = self._message.front_file
	if frontFile ~= nil and string.len(frontFile) > 0 then
		-- create skeleton
		local startIndex, endIndex = string.find(frontFile, ".json")
		local fileName = string.sub(frontFile, 1, startIndex - 1)
		self._frontEffect = QSkeletonView:create(fileName)
		self._skeletonRoot:addChild(self._frontEffect)
		self._frontEffect:playAnimation(EFFECT_ANIMATION, true)
	end

	local backFile = self._message.back_file
	if backFile ~= nil and string.len(backFile) > 0 then
		-- create skeleton
		local startIndex, endIndex = string.find(backFile, ".json")
		local fileName = string.sub(backFile, 1, startIndex - 1)
		self._backEffect = QSkeletonView:create(fileName)
		self._skeletonRoot:addChild(self._backEffect)
		self._backEffect:playAnimation(EFFECT_ANIMATION, true)
	end

	-- button and lable at left top
	local positionX = 10 
	local positionY = -20
	local deltaX = 180

	self._nameLabel = ui.newTTFLabel( {
		text = "Effect",
		font = global.font_monaco,
		color = display.COLOR_ORANGE,
		size = 25 } )
	self._nameLabel:setAnchorPoint(ccp(0.0, 0.5))
	self._infomationNode:addChild(self._nameLabel)
	self._nameLabel:setPosition(positionX, positionY)
	positionY = positionY - 25

	self._currentMode = QESkeletonViewer.Effect_MODE
end

-- edit effect

function QESkeletonViewer:editEffectPauseAllAnimations()
	if self._skeleton ~= nil then
		self._skeleton:pauseAnimation()
	end
	if self._frontEffect ~= nil then
		self._frontEffect:pauseAnimation()
	end
	if self._backEffect ~= nil then
		self._backEffect:pauseAnimation()
	end
end

function QESkeletonViewer:onEditEffectAnimationClicked(tag)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	local name = self._animationNames[tag]
	if name ~= nil and self._skeleton ~= nil then
		self._skeleton:resetActorWithAnimation(ANIMATION.STAND, false)
		self._skeleton:playAnimation(name, false)
		self._currentAnimation = name
		self._currentAnimationFrameCount = self._skeleton:getAnimationFrameCount(self._currentAnimation)
		self._currentAnimationLabel:setString(self._currentAnimation)
		self._frameCountLabel:setString("Frame Count: " .. tostring(self._currentAnimationFrameCount))
	end
end

function QESkeletonViewer:onEditEffectDisplayActorClicked()
	if self._isDisplayActor == true then
		self._displayActorCheckMenu:setString("No")
		self._skeleton:setVisible(false)
		self._isDisplayActor = false
	else
		self._displayActorCheckMenu:setString("Yes")
		self._skeleton:setVisible(true)
		self._isDisplayActor = true
	end
end

function QESkeletonViewer:onEditEffectFlipActorClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	if self._isFlipActor == true then
		self._flipActorCheckMenu:setString("No")
		local scale = self._message.actor_scale or 1.0
		self._skeleton:setSkeletonScaleX(scale)
		self._isFlipActor = false
	else
		self._flipActorCheckMenu:setString("Yes")
		local scale = self._message.actor_scale or 1.0
		scale = -scale
		self._skeleton:setSkeletonScaleX(scale)
		self._isFlipActor = true
	end
end

function QESkeletonViewer:onEditEffectDisplayDummyClicked()
	if self._isDisplayDummy == true then
		self._displayDummyCheckMenu:setString("No")
		for _, label in ipairs(self._dummyLabels) do
			label:setVisible(false)
		end
		self._isDisplayDummy = false
	else
		self._displayDummyCheckMenu:setString("Yes")
		for _, label in ipairs(self._dummyLabels) do
			label:setVisible(true)
		end
		self._isDisplayDummy = true
	end
end

function QESkeletonViewer:onEditEffectDisplayFreeDummyClicked()
	if self._isDisplayFreeDummy == true then
		self._displayFreeDummyCheckMenu:setString("No")
		for _, label in ipairs(self._freeDummyLabels) do
			label:setVisible(false)
		end
		self._isDisplayFreeDummy = false
	else
		self._displayFreeDummyCheckMenu:setString("Yes")
		for _, label in ipairs(self._freeDummyLabels) do
			label:setVisible(true)
		end
		self._isDisplayFreeDummy = true
	end
end

function QESkeletonViewer:onEditEffectDummyClicked(tag)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	local dummyName = self._dummyNames[tag]
	if self._currentDummy ~= dummyName then
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:retain()
			if self._currentDummy == "No Dummy" then
				self._frontEffectNode:removeFromParent()
			else
				self._skeleton:detachNodeToBone(self._frontEffectNode)
			end
			self._skeleton:attachNodeToBone(dummyName, self._frontEffectNode, false, self._isFlipWithActor)
			self._frontEffectNode:release()
			self._frontEffect:setPosition(self._offsetX, self._offsetY)
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:retain()
			if self._currentDummy == "No Dummy" then
				self._backEffectNode:removeFromParent()
			else
				self._skeleton:detachNodeToBone(self._backEffectNode)
			end
			self._skeleton:attachNodeToBone(dummyName, self._backEffectNode, true, self._isFlipWithActor)
			self._backEffectNode:release()
			self._backEffectNode:setPosition(self._offsetX, self._offsetY)
		end
		self._skeleton:updateAnimation(0.0)
		self._currentDummyLabel:setString(dummyName)
		self._currentDummy = dummyName
	end
end

function QESkeletonViewer:onEditEffectFreeDummyClicked(tag)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	local dummyName = self._freeDummyNames[tag]
	if self._currentDummy ~= dummyName then
		local positionBottom = {x = 0, y = 0}
		local positionCenter = {x = 0, y = self._message.actor_height * 0.5}
		local positionTop = {x = 0, y = self._message.actor_height}
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:retain()
			if self._currentDummy == "No Dummy" then
				self._frontEffectNode:removeFromParent()
			else
				self._skeleton:detachNodeToBone(self._frontEffectNode)
			end
			self._skeleton:attachNodeToBone(nil, self._frontEffectNode, false, self._isFlipWithActor)
			self._frontEffectNode:release()
			if dummyName == DUMMY.TOP then
				self._frontEffect:setPosition(self._offsetX + positionTop.x, self._offsetY + positionTop.y)
			elseif dummyName == DUMMY.CENTER then
				self._frontEffect:setPosition(self._offsetX + positionCenter.x, self._offsetY + positionCenter.y)
			elseif dummyName == DUMMY.BOTTOM then
				self._frontEffect:setPosition(self._offsetX + positionBottom.x, self._offsetY + positionBottom.y)
			end
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:retain()
			if self._currentDummy == "No Dummy" then
				self._backEffectNode:removeFromParent()
			else
				self._skeleton:detachNodeToBone(self._backEffectNode)
			end
			self._skeleton:attachNodeToBone(nil, self._backEffectNode, true, self._isFlipWithActor)
			self._backEffectNode:release()
			if dummyName == DUMMY.TOP then
				self._backEffect:setPosition(self._offsetX + positionTop.x, self._offsetY + positionTop.y)
			elseif dummyName == DUMMY.CENTER then
				self._backEffect:setPosition(self._offsetX + positionCenter.x, self._offsetY + positionCenter.y)
			elseif dummyName == DUMMY.BOTTOM then
				self._backEffect:setPosition(self._offsetX + positionBottom.x, self._offsetY + positionBottom.y)
			end
		end
		self._skeleton:updateAnimation(0.0)
		self._currentDummyLabel:setString(dummyName)
		self._currentDummy = dummyName
	end
end

function QESkeletonViewer:onEditEffectNoDummyClicked(tag)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	if self._currentDummy ~= "No Dummy" then
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:retain()
			self._skeleton:detachNodeToBone(self._frontEffectNode)
			self._skeletonRoot:addChild(self._frontEffectNode)
			self._frontEffectNode:release()
			self._frontEffectNode:setPosition(0, 0)
			self._frontEffect:setPosition(self._offsetX, self._offsetY)
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:retain()
			self._skeleton:detachNodeToBone(self._backEffectNode)
			self._skeletonRoot:addChild(self._backEffectNode)
			self._backEffectNode:release()
			self._backEffectNode:setPosition(0, 0)
			self._backEffect:setPosition(self._offsetX, self._offsetY)
		end
		self._skeleton:updateAnimation(0.0)
		self._currentDummyLabel:setString("No Dummy")
		self._currentDummy = "No Dummy"
	end
end

-- set position
function QESkeletonViewer:changeEffectOffset(deltaX, deltaY)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	self._offsetX = self._offsetX + deltaX
	self._offsetY = self._offsetY + deltaY

	self._offsetXValueLabel:setString(string.format("%.1f", self._offsetX))
	self._offsetYValueLabel:setString(string.format("%.1f", self._offsetY))

	if self._currentDummy == "No Dummy" then
		if self._frontEffectNode ~= nil then
			self._frontEffect:setPosition(self._offsetX, self._offsetY)
		end
		if self._backEffectNode ~= nil then
			self._backEffect:setPosition(self._offsetX, self._offsetY)
		end
	elseif self._currentDummy == DUMMY.BOTTOM or self._currentDummy == DUMMY.TOP or self._currentDummy == DUMMY.CENTER then
		local positionBottom = {x = 0, y = 0}
		local positionCenter = {x = 0, y = self._message.actor_height * 0.5}
		local positionTop = {x = 0, y = self._message.actor_height}
		if self._currentDummy == DUMMY.TOP then
			if self._frontEffectNode ~= nil then
				self._frontEffect:setPosition(self._offsetX + positionTop.x, self._offsetY + positionTop.y)
			end
			if self._backEffectNode ~= nil then
				self._backEffect:setPosition(self._offsetX + positionTop.x, self._offsetY + positionTop.y)
			end
		elseif self._currentDummy == DUMMY.CENTER then
			if self._frontEffectNode ~= nil then
				self._frontEffect:setPosition(self._offsetX + positionCenter.x, self._offsetY + positionCenter.y)
			end
			if self._backEffectNode ~= nil then
				self._backEffect:setPosition(self._offsetX + positionCenter.x, self._offsetY + positionCenter.y)
			end
		elseif self._currentDummy == DUMMY.BOTTOM then
			if self._frontEffectNode ~= nil then
				self._frontEffect:setPosition(self._offsetX + positionBottom.x, self._offsetY + positionBottom.y)
			end
			if self._backEffectNode ~= nil then
				self._backEffect:setPosition(self._offsetX + positionBottom.x, self._offsetY + positionBottom.y)
			end
		end
	else
		if self._frontEffectNode ~= nil then
			self._frontEffect:setPosition(self._offsetX, self._offsetY)
		end
		if self._backEffectNode ~= nil then
			self._backEffect:setPosition(self._offsetX, self._offsetY)
		end
	end
end

-- set x position
function QESkeletonViewer:onEditEffectDecreaseOffsetXMoreClicked()
	self:changeEffectOffset(-1.0, 0)
end

function QESkeletonViewer:onEditEffectDecreaseOffsetXClicked()
	self:changeEffectOffset(-0.1, 0)
end

function QESkeletonViewer:onEditEffectIncreaseOffsetXClicked()
	self:changeEffectOffset(0.1, 0)
end

function QESkeletonViewer:onEditEffectIncreaseOffsetXMoreClicked()
	self:changeEffectOffset(1.0, 0)
end

--set y position
function QESkeletonViewer:onEditEffectDecreaseOffsetYMoreClicked()
	self:changeEffectOffset(0.0, -1.0)
end

function QESkeletonViewer:onEditEffectDecreaseOffsetYClicked()
	self:changeEffectOffset(0.0, -0.1)
end

function QESkeletonViewer:onEditEffectIncreaseOffsetYClicked()
	self:changeEffectOffset(0.0, 1.0)
end

function QESkeletonViewer:onEditEffectIncreaseOffsetYMoreClicked()
	self:changeEffectOffset(0.0, 0.1)
end

-- set scale
function QESkeletonViewer:changeEffectScale(deltaS)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	self._scale = self._scale + deltaS
	self._scaleValueLabel:setString(string.format("%.2f", self._scale))

	if self._frontEffectNode ~= nil then
		self._frontEffect:setSkeletonScaleX(self._scale)
		self._frontEffect:setSkeletonScaleY(self._scale)
	end
	if self._backEffectNode ~= nil then
		self._backEffect:setSkeletonScaleX(self._scale)
		self._backEffect:setSkeletonScaleY(self._scale)
	end
end

function QESkeletonViewer:onEditEffectDecreaseScaleMoreClicked()
	self:changeEffectScale(-0.1)
end

function QESkeletonViewer:onEditEffectDecreaseScaleClicked()
	self:changeEffectScale(-0.01)
end

function QESkeletonViewer:onEditEffectIncreaseScaleClicked()
	self:changeEffectScale(0.01)
end

function QESkeletonViewer:onEditEffectIncreaseScaleMoreClicked()
	self:changeEffectScale(0.1)
end

-- set rotation
function QESkeletonViewer:changeEffectRotation(deltaR)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	self._rotation = self._rotation + deltaR
	self._rotationValueLabel:setString(string.format("%.1f", self._rotation))

	if self._frontEffectNode ~= nil then
		self._frontEffect:setRotation(self._rotation)
	end
	if self._backEffectNode ~= nil then
		self._backEffect:setRotation(self._rotation)
	end
end

function QESkeletonViewer:onEditEffectDecreaseRotationMoreClicked()
	self:changeEffectRotation(-1.0)
end

function QESkeletonViewer:onEditEffectDecreaseRotationClicked()
	self:changeEffectRotation(-0.1)
end

function QESkeletonViewer:onEditEffectIncreaseRotationClicked()
	self:changeEffectRotation(0.1)
end

function QESkeletonViewer:onEditEffectIncreaseRotationMoreClicked()
	self:changeEffectRotation(1.0)
end

-- set play speed
function QESkeletonViewer:changeEffectPlaySpeed(deltaPS)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	self._playSpeed = self._playSpeed + deltaPS
	if self._playSpeed < 0 then
		self._playSpeed = 0
	end
	self._playSpeedValueLabel:setString(string.format("%.2f", self._playSpeed))

	if self._frontEffectNode ~= nil then
		self._frontEffect:setAnimationScaleOriginal(self._playSpeed)
	end
	if self._backEffectNode ~= nil then
		self._backEffect:setAnimationScaleOriginal(self._playSpeed)
	end
end

function QESkeletonViewer:onEditEffectDecreasePlaySpeedMoreClicked()
	self:changeEffectPlaySpeed(-0.1)
end

function QESkeletonViewer:onEditEffectDecreasePlaySpeedClicked()
	self:changeEffectPlaySpeed(-0.01)
end

function QESkeletonViewer:onEditEffectIncreasePlaySpeedClicked()
	self:changeEffectPlaySpeed(0.01)
end

function QESkeletonViewer:onEditEffectIncreasePlaySpeedMoreClicked()
	self:changeEffectPlaySpeed(0.1)
end

-- set delay time
function QESkeletonViewer:changeEffectDelayTime(deltaDT)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	self._delay = self._delay + deltaDT
	if self._delay < 0 then
		self._delay = 0
	end

	self._skeleton:playAnimation(self._currentAnimation, false)
	self._skeleton:updateAnimation(self._delay)

	if self._frontEffectNode ~= nil then
		self._frontEffectNode:setVisible(true)
		self._frontEffect:playAnimation(EFFECT_ANIMATION, false)
		self._frontEffect:updateAnimation(0)
	end
	if self._backEffectNode ~= nil then
		self._backEffectNode:setVisible(true)
		self._backEffect:playAnimation(EFFECT_ANIMATION, false)
		self._backEffect:updateAnimation(0)
	end

	self._delayValueLabel:setString(string.format("%.2f", self._delay))
end

function QESkeletonViewer:onEditEffectDecreaseDelayMoreClicked()
	self:changeEffectDelayTime(-0.1)
end

function QESkeletonViewer:onEditEffectDecreaseDelayClicked()
	self:changeEffectDelayTime(-0.01)
end

function QESkeletonViewer:onEditEffectIncreaseDelayClicked()
	self:changeEffectDelayTime(0.01)
end

function QESkeletonViewer:onEditEffectIncreaseDelayMoreClicked()
	self:changeEffectDelayTime(0.1)
end

-- others
function QESkeletonViewer:onEditEffectFlipWithActorClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_EDIT_MODE then
		return
	end

	if self._isFlipWithActor == true then
		self._flipWithActorCheckMenu:setString("No")
		self._isFlipWithActor = false
	else
		self._flipWithActorCheckMenu:setString("Yes")
		self._isFlipWithActor = true
	end

	if self._currentDummy == "No Dummy" then
	else
		local dummy = self._currentDummy
		if self._currentDummy == DUMMY.BOTTOM or self._currentDummy == DUMMY.TOP or self._currentDummy == DUMMY.CENTER then
			dummy = nil
		end
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:retain()
			self._skeleton:detachNodeToBone(self._frontEffectNode)
			self._skeleton:attachNodeToBone(dummy, self._frontEffectNode, false, self._isFlipWithActor)
			self._frontEffectNode:release()
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:retain()
			self._skeleton:detachNodeToBone(self._backEffectNode)
			self._skeleton:attachNodeToBone(dummy, self._backEffectNode, true, self._isFlipWithActor)
			self._backEffectNode:release()
		end
	end
	self._skeleton:updateAnimation(0.0)
end

function QESkeletonViewer:onEditEffectModeClicked()
	if self._effectEditMode == QESkeletonViewer.EFFECT_EDIT_MODE then
		self._effectEditMode = QESkeletonViewer.EFFECT_PLAY_MODE
		self._modeCheckMenu:setString("Play Mode")
		if self._effectPlayMode == QESkeletonViewer.EFFECT_FRAME_PLAY then
			self:onEditEffectUpdateFrameModeFrame(0)
		elseif self._effectPlayMode == QESkeletonViewer.EFFECT_CONTINUE_PLAY then
			self._isStoped = true
		end
	else
		self._effectEditMode = QESkeletonViewer.EFFECT_EDIT_MODE
		self._modeCheckMenu:setString("Edit Mode")
		self._skeleton:playAnimation(self._currentAnimation, false)
		self._skeleton:updateAnimation(self._delay)
		if self._frontEffectNode ~= nil then
			self._frontEffect:playAnimation(EFFECT_ANIMATION, false)
			self._frontEffect:updateAnimation(0)
		end
		if self._backEffectNode ~= nil then
			self._backEffect:playAnimation(EFFECT_ANIMATION, false)
			self._backEffect:updateAnimation(0)
		end

	end
end

function QESkeletonViewer:onEditEffectPlayModeClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode == QESkeletonViewer.EFFECT_FRAME_PLAY then
		self._effectPlayMode = QESkeletonViewer.EFFECT_CONTINUE_PLAY
		self._playModeCheckMenu:setString("Continue Play")
		self._isStoped = true
	else
		self._effectPlayMode = QESkeletonViewer.EFFECT_FRAME_PLAY
		self._playModeCheckMenu:setString("Frame Play")
		self:onEditEffectUpdateFrameModeFrame(0)
	end
end

function QESkeletonViewer:onEditEffectLoopAnimationClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._isLoopAnimation == true then
		self._isLoopAnimation = false
		self._loopAnimationCheckMenu:setString("No")
	else
		self._isLoopAnimation = true
		self._loopAnimationCheckMenu:setString("Yes")
	end
	self._isStoped = true
end

function QESkeletonViewer:onEditEffectPreviousFrameClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_FRAME_PLAY then
		return
	end
	
	if self._currentFrame == 0 then
		return
	end

	self:onEditEffectUpdateFrameModeFrame(self._currentFrame - 0.5)
end

function QESkeletonViewer:onEditEffectNextFrameClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_FRAME_PLAY then
		return
	end

	-- if self._currentFrame == self._currentAnimationFrameCount then
	-- 	return
	-- end
	
	self:onEditEffectUpdateFrameModeFrame(self._currentFrame + 0.5)
end

function QESkeletonViewer:onEditEffectUpdateFrameModeFrame(frame)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_FRAME_PLAY then
		return 
	end

	self._currentFrame = frame
	self._currentFrameLabel:setString(tostring(self._currentFrame))

	local updateTime = self._currentFrame / 30

	self._skeleton:playAnimation(self._currentAnimation, false)
	self._skeleton:updateAnimation(updateTime)

	if updateTime <= self._delay then
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:setVisible(false)
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:setVisible(false)
		end
	else
		if self._frontEffectNode ~= nil then
			self._frontEffectNode:setVisible(true)
			self._frontEffect:playAnimation(EFFECT_ANIMATION, false)
			local deltaTime = updateTime - self._delay
			local frames = math.floor(deltaTime * 30) -- equal to (deltaTime / ( 1.0 / 30))
			local time = frames / 30
			if time < 1 / 60 then
				time = 0;
			end
			self._frontEffect:updateAnimation(time)
		end
		if self._backEffectNode ~= nil then
			self._backEffectNode:setVisible(true)
			self._backEffect:playAnimation(EFFECT_ANIMATION, false)
			local deltaTime = updateTime - self._delay
			local frames = math.floor(deltaTime * 30) -- equal to (deltaTime / ( 1.0 / 30))
			local time = frames / 30
			if time < 1 / 60 then
				time = 0;
			end
			self._backEffect:updateAnimation(time)
		end
	end
end

function QESkeletonViewer:onEditEffectPlayClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_CONTINUE_PLAY then
		return
	end

	self._isStoped = false
	self._currentTime = 0
	self._skeleton:playAnimation(self._currentAnimation, self._isLoopAnimation)
	self._skeleton:updateAnimation(0.0)
	if self._frontEffectNode ~= nil then
		self._frontEffect:playAnimation(EFFECT_ANIMATION, self._isLoopAnimation)
		self._frontEffect:updateAnimation(0.0)
		if self._delay > 0 then
			self._frontEffectNode:setVisible(false)
		else
			self._frontEffectNode:setVisible(true)
		end
	end
	if self._backEffectNode ~= nil then
		self._backEffect:playAnimation(EFFECT_ANIMATION, self._isLoopAnimation)
		self._backEffect:updateAnimation(0.0)
		if self._delay > 0 then
			self._backEffectNode:setVisible(false)
		else
			self._backEffectNode:setVisible(true)
		end
	end

	self._isDelayPassed = false
	if self._delay <= 0 then
		self._isDelayPassed = true
	end

	if self._frameUpdateId == nil and self._stepMenu == nil then
		self._frameUpdateId = scheduler.scheduleUpdateGlobal(handler(self, QESkeletonViewer.onEditEffectFrame))
	end
end

function QESkeletonViewer:onEditEffectStopClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_CONTINUE_PLAY then
		return
	end

	self._isStoped = true
end

function QESkeletonViewer:onEditEffectStepClicked()
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_CONTINUE_PLAY then
		return
	end

	self:onEditEffectFrame(1/60)
end

function QESkeletonViewer:onEditEffectFrame(dt)
	if self._effectEditMode ~= QESkeletonViewer.EFFECT_PLAY_MODE then
		return
	end

	if self._effectPlayMode ~= QESkeletonViewer.EFFECT_CONTINUE_PLAY or self._isStoped == true then
		return
	end

	local lastTime = self._currentTime
	self._currentTime = self._currentTime + dt

	self._skeleton:updateAnimation(dt)
	if self._isDelayPassed == true then
		if self._frontEffectNode ~= nil then
			self._frontEffect:updateAnimation(dt)
			-- self._frontEffect:playAnimation(EFFECT_ANIMATION, self._isLoopAnimation)
			-- local deltaTime = self._currentTime - self._delay
			-- local frames = math.floor(deltaTime * 30) -- equal to (deltaTime / ( 1.0 / 30))
			-- local time = frames / 30
			-- if time < 1 / 60 then
			-- 	time = 0;
			-- end
			-- self._frontEffect:updateAnimation(time)
		end
		if self._backEffectNode ~= nil then
			self._backEffect:updateAnimation(dt)
			-- self._backEffect:playAnimation(EFFECT_ANIMATION, self._isLoopAnimation)
			-- local deltaTime = self._currentTime - self._delay
			-- local frames = math.floor(deltaTime * 30) -- equal to (deltaTime / ( 1.0 / 30))
			-- local time = frames / 30
			-- if time < 1 / 60 then
			-- 	time = 0;
			-- end
			-- self._backEffect:updateAnimation(time)
		end
	else
		if self._delay > 0 and lastTime <= self._delay and self._currentTime > self._delay then
			if self._frontEffectNode ~= nil then
				self._frontEffectNode:setVisible(true)
			end
			if self._backEffectNode ~= nil then
				self._backEffectNode:setVisible(true)
			end
			self._isDelayPassed = true
		end
	end
end

function QESkeletonViewer:onEditEffect()
	self._axisNode:setPosition(display.cx, display.cy * 0.5)
	self._skeletonRoot:setPosition(display.cx, display.cy * 0.5)

	local actorFile = self._message.actor_file
	if actorFile ~= nil and string.len(actorFile) > 0 then
		-- create skeleton
		local startIndex, endIndex = string.find(actorFile, ".json")
		local fileName = string.sub(actorFile, 1, startIndex - 1)
		self._skeleton = QSkeletonActor:create(fileName)
		self._skeletonRoot:addChild(self._skeleton)
		self._skeleton:playAnimation(ANIMATION.STAND, false)
		self._skeleton:setSkeletonScaleX(self._message.actor_scale or 1.0)
		self._skeleton:setSkeletonScaleY(self._message.actor_scale or 1.0)
		self._currentAnimation = ANIMATION.STAND

		-- attach dummy lable
		self._dummyLabels = {}
		self._freeDummyLabels = {}
		self._dummyNames = {}
		self._freeDummyNames = {}
		for dummyKey, dummyName in pairs(DUMMY) do
			if dummyName == DUMMY.TOP or dummyName == DUMMY.CENTER or dummyName == DUMMY.BOTTOM then
				if self._message.actor_height > 0 then
					local node = CCNode:create()
					local label = ui.newTTFLabel( {
						text = dummyName,
						font = global.font_monaco,
						color = display.COLOR_GREEN,
						size = 20 } )
					node:addChild(label)
					self._skeleton:attachNodeToBone(nil, node, true)
					label:setVisible(false)
					table.insert(self._freeDummyLabels, label)
					table.insert(self._freeDummyNames, dummyName)
					if dummyName == DUMMY.TOP then
						label:setPosition(0, self._message.actor_height)
					elseif dummyName == DUMMY.CENTER then
						label:setPosition(0, self._message.actor_height * 0.5)
					end
				end
			else
				if self._skeleton:isBoneExist(dummyName) == true then
					local label = ui.newTTFLabel( {
						text = dummyName,
						font = global.font_monaco,
						size = 20 } )
					self._skeleton:attachNodeToBone(dummyName, label, true)
					label:setVisible(false)
					table.insert(self._dummyLabels, label)
					table.insert(self._dummyNames, dummyName)
				end
			end
		end

		local positionBottom = {x = 0, y = 0}
		local positionCenter = {x = 0, y = self._message.actor_height * 0.5}
		local positionTop = {x = 0, y = self._message.actor_height}

		self._isFlipWithActor = self._message.is_file_with_actor or true
		self._isLayOnTheGround = self._message.is_lay_on_the_ground or false

		-- front effect
		self._frontEffectNode = nil
		self._frontEffect = nil
		local frontEffectFile = self._message.front_file
		if frontEffectFile ~= nil and string.len(frontEffectFile) > 0 then
			local startIndex, endIndex = string.find(frontEffectFile, ".json")
			local fileName = string.sub(frontEffectFile, 1, startIndex - 1)
			self._frontEffectNode = CCNode:create()
			self._frontEffect = QSkeletonView:create(fileName)
			self._frontEffectNode:addChild(self._frontEffect)
			-- position
			self._frontEffect:setPosition(self._message.offset_x, self._message.offset_y)
			-- scale
			self._frontEffect:setSkeletonScaleX(self._message.scale)
			self._frontEffect:setSkeletonScaleY(self._message.scale)
			-- rotation
			self._frontEffect:setRotation(self._message.rotation)
			-- speed
			self._frontEffect:setAnimationScale(self._message.play_speed)

			-- attach to dummy
			local dummy = self._message.dummy
			printInfo("dummy:" .. dummy)
			if dummy == nil or string.len(dummy) <= 0 then
				self._skeletonRoot:addChild(self._frontEffectNode)
			else
				if dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER then
					if dummy == DUMMY.TOP then
						local x, y = self._frontEffect:getPosition()
						self._frontEffect:setPosition(x + positionTop.x, y + positionTop.y)
					elseif dummy == DUMMY.CENTER then
						local x, y = self._frontEffect:getPosition()
						self._frontEffect:setPosition(x + positionCenter.x, y + positionCenter.y)
					end
					self._skeleton:attachNodeToBone(nil, self._frontEffectNode, false, self._isFlipWithActor)
				else
					self._skeleton:attachNodeToBone(dummy, self._frontEffectNode, false, self._isFlipWithActor)
				end
			end
			
			-- play animation
			self._frontEffect:playAnimation(EFFECT_ANIMATION, false)
		end

		-- back effect
		self._backEffectNode = nil
		self._backEffect = nil
		local backEffectFile = self._message.back_file
		if backEffectFile ~= nil and string.len(backEffectFile) > 0 then
			local startIndex, endIndex = string.find(backEffectFile, ".json")
			local fileName = string.sub(backEffectFile, 1, startIndex - 1)
			self._backEffectNode = CCNode:create()
			self._backEffect = QSkeletonView:create(fileName)
			self._backEffectNode:addChild(self._backEffect)
			-- position
			self._backEffect:setPosition(self._message.offset_x, self._message.offset_y)
			-- scale
			self._backEffect:setSkeletonScaleX(self._message.scale)
			self._backEffect:setSkeletonScaleY(self._message.scale)
			-- rotation
			self._backEffect:setRotation(self._message.rotation)
			-- speed
			self._backEffect:setAnimationScale(self._message.play_speed)

			-- attach to dummy
			local dummy = self._message.dummy
			if dummy == nil or string.len(dummy) <= 0 then
				self._skeletonRoot:addChild(self._backEffectNode)
			else
				if dummy == DUMMY.BOTTOM or dummy == DUMMY.TOP or dummy == DUMMY.CENTER then
					if dummy == DUMMY.TOP then
						local x, y = self._backEffect:getPosition()
						self._backEffect:setPosition(x + positionTop.x, y + positionTop.y)
					elseif dummy == DUMMY.CENTER then
						local x, y = self._backEffect:getPosition()
						self._backEffect:setPosition(x + positionCenter.x, y + positionCenter.y)
					end
					self._skeleton:attachNodeToBone(nil, self._backEffectNode, true, self._isFlipWithActor)
				else
					self._skeleton:attachNodeToBone(dummy, self._backEffectNode, true, self._isFlipWithActor)
				end
			end
			
			-- play animation
			self._backEffect:playAnimation(EFFECT_ANIMATION, false)
		end

		self:editEffectPauseAllAnimations()

		-- editor button and infomation

		-- 1. file information
		local positionX = 10 
		local positionY = -15
		local deltaX = 180

		local strings = string.split(self._message.actor_file, "/")
		if #strings <= 1 then
			strings = string.split(self._message.actor_file, "\\")
		end
		local actorFileName = strings[#strings]
		self._acotrFileLabel = ui.newTTFLabel( {
			text = "Actor:        " .. actorFileName,
			font = global.font_monaco,
			color = display.COLOR_ORANGE,
			size = 20 } )
		self._acotrFileLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._acotrFileLabel)
		self._acotrFileLabel:setPosition(positionX, positionY)
		positionY = positionY - 20

		local frontEffectFileName = "nil"
		if self._message.front_file ~= nil and string.len(self._message.front_file) > 0 then
			strings = string.split(self._message.front_file, "/")
			if #strings <= 1 then
				strings = string.split(self._message.front_file, "\\")
			end
			frontEffectFileName = strings[#strings]
		end
		self._frontEffectFileLabel = ui.newTTFLabel( {
			text = "Front Effect: " .. frontEffectFileName,
			font = global.font_monaco,
			color = display.COLOR_ORANGE,
			size = 20 } )
		self._frontEffectFileLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._frontEffectFileLabel)
		self._frontEffectFileLabel:setPosition(positionX, positionY)
		positionY = positionY - 20

		local backEffectFileName = "nil"
		if self._message.back_file ~= nil and string.len(self._message.back_file) > 0 then
			strings = string.split(self._message.back_file, "/")
			if #strings <= 1 then
				strings = string.split(self._message.back_file, "\\")
			end
			backEffectFileName = strings[#strings]
		end
		self._backEffectFileLabel = ui.newTTFLabel( {
			text = "Back Effect:  " .. backEffectFileName,
			font = global.font_monaco,
			color = display.COLOR_ORANGE,
			size = 20 } )
		self._backEffectFileLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._backEffectFileLabel)
		self._backEffectFileLabel:setPosition(positionX, positionY)
		positionY = positionY - 30

		-- 2. actor animation and actor display switch
		self._displayActorLabel = ui.newTTFLabel( {
			text = "Actor",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._displayActorLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._displayActorLabel)
		self._displayActorLabel:setPosition(positionX, positionY)

		self._displayActorCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDisplayActorClicked),
			text = "Yes",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._displayActorCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._displayActorCheckMenu)
		self._displayActorCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayActor = true
		positionY = positionY - 20

		self._flipActorLabel = ui.newTTFLabel( {
			text = "Flip Actor",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._flipActorLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._flipActorLabel)
		self._flipActorLabel:setPosition(positionX, positionY)

		self._flipActorCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectFlipActorClicked),
			text = "No",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._flipActorCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._flipActorCheckMenu)
		self._flipActorCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isFlipActor = false
		positionY = positionY - 20

		self._currentAnimationTitleLabel = ui.newTTFLabel( {
			text = "Current Animation:",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._currentAnimationTitleLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._currentAnimationTitleLabel)
		self._currentAnimationTitleLabel:setPosition(positionX, positionY)

		self._currentAnimationLabel = ui.newTTFLabel( {
			text = self._currentAnimation,
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._currentAnimationLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._currentAnimationLabel)
		self._currentAnimationLabel:setPosition(positionX + deltaX * 1.2, positionY)
		positionY = positionY - 20

		self._actorAnimationLabel = ui.newTTFLabel( {
			text = "Actor Animation:",
			font = global.font_monaco,
			color = display.COLOR_GREEN,
			size = 20 } )
		self._actorAnimationLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._actorAnimationLabel)
		self._actorAnimationLabel:setPosition(positionX, positionY)
		positionY = positionY - 20

		local animationNames = self._skeleton:getAllAnimationName()
		local animationCount = animationNames:count()
		self._animationNames = {}
		for i = 1, animationCount do
			local animationName = tolua.cast(animationNames:objectAtIndex(i - 1), "CCString")
			local animationText = animationName:getCString()
			local menuItem = ui.newTTFLabelMenuItem( {
				listener = handler(self, QESkeletonViewer.onEditEffectAnimationClicked),
				text = animationText,
				font = global.font_monaco,
				size = 20,
				color = display.COLOR_GREEN,
				tag = i } )
			menuItem:setAnchorPoint(ccp(0.0, 0.5))
			self._menu:addChild(menuItem)
			if i % 2 ~= 0 then
				menuItem:setPosition(positionX, positionY)
			else
				menuItem:setPosition(positionX + deltaX, positionY)
				positionY = positionY - 20
			end
			table.insert(self._animationNames, animationText)
		end
		if animationCount % 2 ~= 0 then
			positionY = positionY - 30
		else
			positionY = positionY - 10
		end

		-- 3. effect dummy
		self._displayDummyLabel = ui.newTTFLabel( {
			text = "Dummy",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._displayDummyLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._displayDummyLabel)
		self._displayDummyLabel:setPosition(positionX, positionY)

		self._displayDummyCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDisplayDummyClicked),
			text = "No",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._displayDummyCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._displayDummyCheckMenu)
		self._displayDummyCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayDummy = false
		positionY = positionY - 20

		self._displayFreeDummyLabel = ui.newTTFLabel( {
			text = "Free Dummy",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._displayFreeDummyLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._displayFreeDummyLabel)
		self._displayFreeDummyLabel:setPosition(positionX, positionY)

		self._displayFreeDummyCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDisplayFreeDummyClicked),
			text = "No",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._displayFreeDummyCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._displayFreeDummyCheckMenu)
		self._displayFreeDummyCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isDisplayFreeDummy = false
		positionY = positionY - 20

		self._currentDummyTitleLabel = ui.newTTFLabel( {
			text = "Current Dummy:",
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._currentDummyTitleLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._currentDummyTitleLabel)
		self._currentDummyTitleLabel:setPosition(positionX, positionY)

		self._currentDummy = self._message.dummy or "No Dummy"
		self._currentDummyLabel = ui.newTTFLabel( {
			text = self._currentDummy,
			font = global.font_monaco,
			color = display.COLOR_BLUE,
			size = 20 } )
		self._currentDummyLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._currentDummyLabel)
		self._currentDummyLabel:setPosition(positionX + deltaX, positionY)
		positionY = positionY - 20

		for i, dummyName in ipairs(self._dummyNames) do
			local menuItem = ui.newTTFLabelMenuItem( {
				listener = handler(self, QESkeletonViewer.onEditEffectDummyClicked),
				text = dummyName,
				font = global.font_monaco,
				size = 20,
				color = display.COLOR_BLUE,
				tag = i } )
			menuItem:setAnchorPoint(ccp(0.0, 0.5))
			self._menu:addChild(menuItem)
			menuItem:setPosition(positionX, positionY)
			positionY = positionY - 20
		end
		if #self._dummyNames % 2 ~= 0 then
			positionY = positionY - 20
		end

		for i, dummyName in ipairs(self._freeDummyNames) do
			local menuItem = ui.newTTFLabelMenuItem( {
				listener = handler(self, QESkeletonViewer.onEditEffectFreeDummyClicked),
				text = dummyName,
				font = global.font_monaco,
				size = 20,
				color = display.COLOR_BLUE,
				tag = i } )
			menuItem:setAnchorPoint(ccp(0.0, 0.5))
			self._menu:addChild(menuItem)
			menuItem:setPosition(positionX, positionY)
			positionY = positionY - 20
		end

		local noDummyMenuItem = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectNoDummyClicked),
			text = "No Dummy",
			font = global.font_monaco,
			size = 20,
			color = display.COLOR_BLUE,
			tag = i } )
		noDummyMenuItem:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(noDummyMenuItem)
		noDummyMenuItem:setPosition(positionX, positionY)
		positionY = positionY - 20

		-- self._effectDelay = self._message.delay

		-- 4. effect attribute
		positionX = display.width - 300 
		positionY = -15
		deltaX = 150

		self._offsetXLabel = ui.newTTFLabel( {
			text = "Offset X:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._offsetXLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._offsetXLabel)
		self._offsetXLabel:setPosition(positionX, positionY)

		self._decreaseOffsetXMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseOffsetXMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseOffsetXMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseOffsetXMoreMenu)
		self._decreaseOffsetXMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreaseOffsetXMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseOffsetXClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseOffsetXMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseOffsetXMenu)
		self._decreaseOffsetXMenu:setPosition(positionX + deltaX + 20, positionY)

		self._offsetX = self._message.offset_x or 0.00
		self._offsetXValueLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._offsetX),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._offsetXValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._offsetXValueLabel)
		self._offsetXValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increaseOffsetXMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseOffsetXClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseOffsetXMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseOffsetXMenu)
		self._increaseOffsetXMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increaseOffsetXMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseOffsetXMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseOffsetXMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseOffsetXMoreMenu)
		self._increaseOffsetXMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._offsetYLabel = ui.newTTFLabel( {
			text = "Offset Y:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._offsetYLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._offsetYLabel)
		self._offsetYLabel:setPosition(positionX, positionY)

		self._decreaseOffsetYMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseOffsetYMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseOffsetYMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseOffsetYMoreMenu)
		self._decreaseOffsetYMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreaseOffsetYMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseOffsetYClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseOffsetYMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseOffsetYMenu)
		self._decreaseOffsetYMenu:setPosition(positionX + deltaX + 20, positionY)

		self._offsetY = self._message.offset_y or 0.00
		self._offsetYValueLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._offsetY),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._offsetYValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._offsetYValueLabel)
		self._offsetYValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increaseOffsetYMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseOffsetYClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseOffsetYMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseOffsetYMenu)
		self._increaseOffsetYMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increaseOffsetYMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseOffsetYMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseOffsetYMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseOffsetYMoreMenu)
		self._increaseOffsetYMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._scaleLabel = ui.newTTFLabel( {
			text = "Scale:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._scaleLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._scaleLabel)
		self._scaleLabel:setPosition(positionX, positionY)

		self._decreaseScaleMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseScaleMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseScaleMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseScaleMoreMenu)
		self._decreaseScaleMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreaseScaleMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseScaleClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseScaleMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseScaleMenu)
		self._decreaseScaleMenu:setPosition(positionX + deltaX + 20, positionY)

		self._scale = self._message.scale or 1.0
		self._scaleValueLabel = ui.newTTFLabel( {
			text = string.format("%.2f", self._scale),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._scaleValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._scaleValueLabel)
		self._scaleValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increaseScaleMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseScaleClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseScaleMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseScaleMenu)
		self._increaseScaleMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increaseScaleMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseScaleMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseScaleMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseScaleMoreMenu)
		self._increaseScaleMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._rotationLabel = ui.newTTFLabel( {
			text = "Rotation:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._rotationLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._rotationLabel)
		self._rotationLabel:setPosition(positionX, positionY)

		self._decreaseRotationMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseRotationMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseRotationMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseRotationMoreMenu)
		self._decreaseRotationMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreaseRotationMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseRotationClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseRotationMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseRotationMenu)
		self._decreaseRotationMenu:setPosition(positionX + deltaX + 20, positionY)

		self._rotation = self._message.rotation or 0.0
		self._rotationValueLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._rotation),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._rotationValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._rotationValueLabel)
		self._rotationValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increaseRotationMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseRotationClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseRotationMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseRotationMenu)
		self._increaseRotationMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increaseRotationMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseRotationMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseRotationMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseRotationMoreMenu)
		self._increaseRotationMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._playSpeedLabel = ui.newTTFLabel( {
			text = "Play Speed:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._playSpeedLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._playSpeedLabel)
		self._playSpeedLabel:setPosition(positionX, positionY)

		self._decreasePlaySpeedMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreasePlaySpeedMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreasePlaySpeedMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreasePlaySpeedMoreMenu)
		self._decreasePlaySpeedMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreasePlaySpeedMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreasePlaySpeedClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreasePlaySpeedMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreasePlaySpeedMenu)
		self._decreasePlaySpeedMenu:setPosition(positionX + deltaX + 20, positionY)

		self._playSpeed = self._message.play_speed or 1.0
		self._playSpeedValueLabel = ui.newTTFLabel( {
			text = string.format("%.1f", self._playSpeed),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._playSpeedValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._playSpeedValueLabel)
		self._playSpeedValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increasePlaySpeedMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreasePlaySpeedClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increasePlaySpeedMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increasePlaySpeedMenu)
		self._increasePlaySpeedMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increasePlaySpeedMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreasePlaySpeedMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increasePlaySpeedMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increasePlaySpeedMoreMenu)
		self._increasePlaySpeedMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._delayLabel = ui.newTTFLabel( {
			text = "Delay:",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._delayLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._delayLabel)
		self._delayLabel:setPosition(positionX, positionY)

		self._decreaseDelayMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseDelayMoreClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseDelayMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseDelayMoreMenu)
		self._decreaseDelayMoreMenu:setPosition(positionX + deltaX, positionY)

		self._decreaseDelayMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectDecreaseDelayClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._decreaseDelayMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._decreaseDelayMenu)
		self._decreaseDelayMenu:setPosition(positionX + deltaX + 20, positionY)

		self._delay = self._message.delay or 0.0
		self._skeleton:updateAnimation(self._delay)
		self._delayValueLabel = ui.newTTFLabel( {
			text = string.format("%.2f", self._delay),
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._delayValueLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._delayValueLabel)
		self._delayValueLabel:setPosition(positionX + deltaX + 40, positionY)

		self._increaseDelayMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseDelayClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseDelayMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseDelayMenu)
		self._increaseDelayMenu:setPosition(positionX + deltaX + 100, positionY)

		self._increaseDelayMoreMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectIncreaseDelayMoreClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._increaseDelayMoreMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._increaseDelayMoreMenu)
		self._increaseDelayMoreMenu:setPosition(positionX + deltaX + 120, positionY)
		positionY = positionY - 20

		self._flipWithActorLabel = ui.newTTFLabel( {
			text = "Is Flip With Actor",
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._flipWithActorLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._flipWithActorLabel)
		self._flipWithActorLabel:setPosition(positionX, positionY)

		local textValue = "Yes"
		if self._isFlipWithActor == false then
			textValue = "No"
		end
		self._flipWithActorCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectFlipWithActorClicked),
			text = textValue,
			font = global.font_monaco,
			color = display.COLOR_WHITE,
			size = 20 } )
		self._flipWithActorCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._flipWithActorCheckMenu)
		self._flipWithActorCheckMenu:setPosition(positionX + deltaX * 1.5, positionY)
		positionY = positionY - 30

		self._effectEditMode = QESkeletonViewer.EFFECT_EDIT_MODE
		self._modeCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectModeClicked),
			text = "Edit Mode",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._modeCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._modeCheckMenu)
		self._modeCheckMenu:setPosition(positionX, positionY)
		positionY = positionY - 20

		self._effectPlayMode = QESkeletonViewer.EFFECT_FRAME_PLAY
		self._playModeCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectPlayModeClicked),
			text = "Frame Play",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._playModeCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._playModeCheckMenu)
		self._playModeCheckMenu:setPosition(positionX, positionY)
		positionY = positionY - 20

		self._currentAnimationFrameCount = self._skeleton:getAnimationFrameCount(self._currentAnimation)
		self._frameCountLabel = ui.newTTFLabel( {
			text = "Frame Count: " .. tostring(self._currentAnimationFrameCount),
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._frameCountLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._frameCountLabel)
		self._frameCountLabel:setPosition(positionX, positionY)
		positionY = positionY - 20

		self._previousFrameMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectPreviousFrameClicked),
			text = "<",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._previousFrameMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._previousFrameMenu)
		self._previousFrameMenu:setPosition(positionX, positionY)

		self._currentFrame = 0
		self._currentFrameLabel = ui.newTTFLabel( {
			text = tostring(self._currentFrame),
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._currentFrameLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._currentFrameLabel)
		self._currentFrameLabel:setPosition(positionX + deltaX * 0.2, positionY)

		self._nextFrameMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectNextFrameClicked),
			text = ">",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._nextFrameMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._nextFrameMenu)
		self._nextFrameMenu:setPosition(positionX + deltaX * 0.6, positionY)
		positionY = positionY - 20

		self._loopAnimationLabel = ui.newTTFLabel( {
			text = "Loop",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._loopAnimationLabel:setAnchorPoint(ccp(0.0, 0.5))
		self._infomationNode:addChild(self._loopAnimationLabel)
		self._loopAnimationLabel:setPosition(positionX, positionY)

		self._loopAnimationCheckMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectLoopAnimationClicked),
			text = "No",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._loopAnimationCheckMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._loopAnimationCheckMenu)
		self._loopAnimationCheckMenu:setPosition(positionX + deltaX, positionY)
		self._isLoopAnimation = false
		positionY = positionY - 20

		self._isStoped = true
		self._playMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectPlayClicked),
			text = "Play",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._playMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._playMenu)
		self._playMenu:setPosition(positionX, positionY)

		self._stopMenu = ui.newTTFLabelMenuItem( {
			listener = handler(self, QESkeletonViewer.onEditEffectStopClicked),
			text = "Stop",
			font = global.font_monaco,
			color = display.COLOR_YELLOW,
			size = 20 } )
		self._stopMenu:setAnchorPoint(ccp(0.0, 0.5))
		self._menu:addChild(self._stopMenu)
		self._stopMenu:setPosition(positionX + deltaX * 0.5, positionY)

		-- self._stepMenu = ui.newTTFLabelMenuItem( {
		-- 	listener = handler(self, QESkeletonViewer.onEditEffectStepClicked),
		-- 	text = "Step",
		-- 	font = global.font_monaco,
		-- 	color = display.COLOR_YELLOW,
		-- 	size = 20 } )
		-- self._stepMenu:setAnchorPoint(ccp(0.0, 0.5))
		-- self._menu:addChild(self._stepMenu)
		-- self._stepMenu:setPosition(positionX + deltaX, positionY)

		positionY = positionY - 20
		
	end

	self._currentMode = QESkeletonViewer.EDIT_MODE
end

return QESkeletonViewer