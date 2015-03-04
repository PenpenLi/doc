
qShader = qShader or {}

qShader.kCCVertexAttrib_Position    = 0
qShader.kCCVertexAttrib_Color       = 1
qShader.kCCVertexAttrib_TexCoords   = 2
qShader.kCCVertexAttrib_MAX         = 3

qShader.kCCUniformPMatrix           = 0
qShader.kCCUniformMVMatrix          = 1
qShader.kCCUniformMVPMatrix         = 2
qShader.kCCUniformTime              = 3
qShader.kCCUniformSinTime           = 4
qShader.kCCUniformCosTime           = 5
qShader.kCCUniformRandom01          = 6
qShader.kCCUniformSampler           = 7
qShader.kCCUniform_MAX              = 8

-- default shader key
qShader.kCCShader_PositionTextureColor             ="ShaderPositionTextureColor"
qShader.kCCShader_PositionTextureGray              ="ShaderPositionTextureGray"
qShader.kCCShader_PositionTextureColorAlphaTest    ="ShaderPositionTextureColorAlphaTest"
qShader.kCCShader_PositionColor                    ="ShaderPositionColor"
qShader.kCCShader_PositionTexture                  ="ShaderPositionTexture"
qShader.kCCShader_PositionTexture_uColor           ="ShaderPositionTexture_uColor"
qShader.kCCShader_PositionTextureA8Color           ="ShaderPositionTextureA8Color"
qShader.kCCShader_Position_uColor                  ="ShaderPosition_uColor"
qShader.kCCShader_PositionLengthTexureColor        ="ShaderPositionLengthTextureColor"
qShader.kCCShader_ControlSwitch                    ="Shader_ControlSwitch"
-- custom shader key
qShader.kQShader_PositionTextureGray               ="QShader_PositionTextureGray"
qShader.kQShader_PositionTextureGrayLuminance      ="QShader_PositionTextureGrayLuminance"
qShader.kQShader_PositionTextureGrayLuminanceAlpha ="kQShader_PositionTextureGrayLuminanceAlpha"

-- uniform names
qShader.kCCUniformPMatrix_s            ="CC_PMatrix"
qShader.kCCUniformMVMatrix_s           ="CC_MVMatrix"
qShader.kCCUniformMVPMatrix_s          ="CC_MVPMatrix"
qShader.kCCUniformTime_s               ="CC_Time"
qShader.kCCUniformSinTime_s            ="CC_SinTime"
qShader.kCCUniformCosTime_s            ="CC_CosTime"
qShader.kCCUniformRandom01_s           ="CC_Random01"
qShader.kCCUniformSampler_s            ="CC_Texture0"
qShader.kCCUniformAlphaTestValue       ="CC_alpha_value"

-- Attribute names
qShader.kCCAttributeNameColor          ="a_color"
qShader.kCCAttributeNamePosition       ="a_position"
qShader.kCCAttributeNameTexCoord       ="a_texCoord"

qShader.CC_ProgramPositionTextureColor = CCShaderCache:sharedShaderCache():programForKey(qShader.kCCShader_PositionTextureColor);
qShader.CC_ProgramPositionTextureGray = CCShaderCache:sharedShaderCache():programForKey(qShader.kCCShader_PositionTextureGray);
qShader.Q_ProgramPositionTextureGray = nil
qShader.Q_ProgramPositionTextureGrayLuminance = nil
qShader.Q_ProgramPositionTextureGrayLuminanceAlpha = nil

qShader.QPositionTextureColor_vert = "				\n\
attribute vec4 a_position;							\n\
attribute vec2 a_texCoord;							\n\
attribute vec4 a_color;								\n\
													\n\
#ifdef GL_ES										\n\
varying lowp vec4 v_fragmentColor;					\n\
varying mediump vec2 v_texCoord;					\n\
#else												\n\
varying vec4 v_fragmentColor;						\n\
varying vec2 v_texCoord;							\n\
#endif												\n\
													\n\
void main()											\n\
{													\n\
    gl_Position = CC_MVPMatrix * a_position;		\n\
	v_fragmentColor = a_color;						\n\
	v_texCoord = a_texCoord;						\n\
}													\n\
"

qShader.QPositionTextureGray_frag = "                 				\n\
#ifdef GL_ES                                						\n\
precision mediump float;                    						\n\
#endif                                      						\n\
																	\n\
uniform sampler2D u_texture;                						\n\
varying vec2 v_texCoord;                    						\n\
varying vec4 v_fragmentColor;               						\n\
																	\n\
void main(void)                             						\n\
{                                           						\n\
	// Convert to greyscale using NTSC weightings               	\n\
	vec4 col = texture2D(u_texture, v_texCoord);                	\n\
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));       	\n\
	gl_FragColor = vec4(grey, grey, grey, col.a) * v_fragmentColor;	\n\
}                                           						\n\
"

qShader.QPositionTextureGrayLuminance_frag = "                 					\n\
#ifdef GL_ES                                									\n\
precision mediump float;                    									\n\
#endif                                      									\n\
																				\n\
uniform sampler2D u_texture;                									\n\
varying vec2 v_texCoord;                    									\n\
varying vec4 v_fragmentColor;               									\n\
																				\n\
void main(void)                             									\n\
{                                           									\n\
	// Convert to greyscale using NTSC weightings               				\n\
	vec4 col = texture2D(u_texture, v_texCoord);                				\n\
	float grey = dot(col.rgb, vec3(0.299, 0.587, 0.114));       				\n\
	vec3 displayColor = v_fragmentColor.rgb * v_fragmentColor.aaa;  			\n\
	gl_FragColor = vec4(grey, grey, grey, col.a) * vec4(displayColor.rgb, 1.0);	\n\
}                                           									\n\
"

function addAttributeToProgram(p, key)
	if p == nil then
		return
	end

	if key == qShader.kQShader_PositionTextureGray then
		p:addAttribute(qShader.kCCAttributeNamePosition, qShader.kCCVertexAttrib_Position);
        p:addAttribute(qShader.kCCAttributeNameColor, qShader.kCCVertexAttrib_Color);
        p:addAttribute(qShader.kCCAttributeNameTexCoord, qShader.kCCVertexAttrib_TexCoords);

    elseif key == qShader.kQShader_PositionTextureGrayLuminance then
    	p:addAttribute(qShader.kCCAttributeNamePosition, qShader.kCCVertexAttrib_Position);
        p:addAttribute(qShader.kCCAttributeNameColor, qShader.kCCVertexAttrib_Color);
        p:addAttribute(qShader.kCCAttributeNameTexCoord, qShader.kCCVertexAttrib_TexCoords);

    elseif key == qShader.kQShader_PositionTextureGrayLuminanceAlpha then
    	p:addAttribute(qShader.kCCAttributeNamePosition, qShader.kCCVertexAttrib_Position);
        p:addAttribute(qShader.kCCAttributeNameColor, qShader.kCCVertexAttrib_Color);
        p:addAttribute(qShader.kCCAttributeNameTexCoord, qShader.kCCVertexAttrib_TexCoords);
    else
    	return
	end
end

-- vert: vertex shader
-- frag: fragment shader
function loadCustomShader(vert, frag, key)
	if vert == nil or frag == nil then
		return nil
	end

	local p = QGLProgram:create(vert, frag)
	assert(p ~= nil, "create custom shader " .. key .. " faild.")

	addAttributeToProgram(p, key)

	p:link();
	p:updateUniforms();
	QUtility:checkGLError()
	CCShaderCache:sharedShaderCache():addProgram(p, key)

	return p
end

function loadAllCustomShaders()
	if qShader.Q_ProgramPositionTextureGray == nil then
		qShader.Q_ProgramPositionTextureGray = loadCustomShader(qShader.QPositionTextureColor_vert, qShader.QPositionTextureGray_frag, qShader.kQShader_PositionTextureGray)
	end

	if qShader.Q_ProgramPositionTextureGrayLuminance == nil then
		qShader.Q_ProgramPositionTextureGrayLuminance = loadCustomShader(qShader.QPositionTextureColor_vert, qShader.QPositionTextureGrayLuminance_frag, qShader.kQShader_PositionTextureGrayLuminance)
	end

	if qShader.Q_ProgramPositionTextureGrayLuminanceAlpha == nil then
		qShader.Q_ProgramPositionTextureGrayLuminanceAlpha = loadCustomShader(qShader.QPositionTextureColor_vert, qShader.QPositionTextureGray_frag, qShader.kQShader_PositionTextureGrayLuminanceAlpha)
	end
end

function reloadCustomShader(p, vert, frag, key)
	if p == nil or vert == nil or frag == nil then
		return 
	end

	p:reset()
	p:initWithVertexShaderByteArray(vert, frag)

	addAttributeToProgram(p, key)

	p:link();
	p:updateUniforms();
	QUtility:checkGLError()
end

function reloadAllCustomShaders()
	local p = CCShaderCache:sharedShaderCache():programForKey(qShader.kQShader_PositionTextureGray)
	if p then
		reloadCustomShader(p, qShader.QPositionTextureColor_vert, qShader.QPositionTextureGray_frag, qShader.kQShader_PositionTextureGray)
	end

	p = CCShaderCache:sharedShaderCache():programForKey(qShader.kQShader_PositionTextureGrayLuminance)
	if p then
		reloadCustomShader(p, qShader.QPositionTextureColor_vert, qShader.QPositionTextureGrayLuminance_frag, qShader.kQShader_PositionTextureGrayLuminance)
	end

	p = CCShaderCache:sharedShaderCache():programForKey(qShader.kQShader_PositionTextureGrayLuminanceAlpha)
	if p then
		reloadCustomShader(p, qShader.QPositionTextureColor_vert, qShader.QPositionTextureGray_frag, qShader.Q_ProgramPositionTextureGrayLuminanceAlpha)
	end
end

function makeNodeFromNormalToGray(node)
	if node == nil or qShader.Q_ProgramPositionTextureGray == nil then
		return
	end

	local program = node:getShaderProgram()
	if program == qShader.CC_ProgramPositionTextureColor then
		node:setShaderProgram(qShader.Q_ProgramPositionTextureGray)
	end

	local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
    	makeNodeFromNormalToGray(children:objectAtIndex(i))
    end
end

function makeNodeFromNormalToGrayLuminance(node)
	if node == nil or qShader.Q_ProgramPositionTextureGrayLuminance == nil then
		return
	end

	local program = node:getShaderProgram()
	if program == qShader.CC_ProgramPositionTextureColor then
		node:setShaderProgram(qShader.Q_ProgramPositionTextureGrayLuminance)
	end

	local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
    	makeNodeFromNormalToGrayLuminance(children:objectAtIndex(i))
    end
end

function makeNodeCascadeOpacityEnabled(node, state)
  if node == nil then
    return
  end

  node:setCascadeOpacityEnabled(state)

  local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
      makeNodeCascadeOpacityEnabled(children:objectAtIndex(i), state)
    end
end

function makeNodeFromNormalToGrayLuminanceAlpha(node)
	if node == nil or qShader.Q_ProgramPositionTextureGrayLuminanceAlpha == nil then
		return
	end

	local program = node:getShaderProgram()
	if program == qShader.CC_ProgramPositionTextureColor then
		node:setShaderProgram(qShader.Q_ProgramPositionTextureGrayLuminanceAlpha)
	end
	node:setOpacityModifyRGB(true)

	local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
    	makeNodeFromNormalToGrayLuminanceAlpha(children:objectAtIndex(i))
    end
end

function makeNodeFromGrayToNormal(node)
	if node == nil then
		return
	end

	local program = node:getShaderProgram()
	if program == qShader.Q_ProgramPositionTextureGray or program == qShader.Q_ProgramPositionTextureGrayLuminance or program == qShader.Q_ProgramPositionTextureGrayLuminanceAlpha then
		node:setShaderProgram(qShader.CC_ProgramPositionTextureColor)
		if program == qShader.Q_ProgramPositionTextureGrayLuminanceAlpha then
			node:setOpacityModifyRGB(false)
		end
	end

	local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
    	makeNodeFromGrayToNormal(children:objectAtIndex(i))
    end
end

function makeNodeOpacity(node, opacity)
	if node == nil then
		return
	end

	node:setOpacity(opacity)

	local children = node:getChildren()
    if children == nil then
        return
    end

    local i = 0
    local len = children:count()
    for i = 0, len - 1, 1 do
    	makeNodeOpacity(children:objectAtIndex(i), opacity)
    end
end

function createSpriteWithSpriteFrame(spriteFrameName)
	if spriteFrameName == nil then
		return
	end

	local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(spriteFrameName)
	if spriteFrame == nil then
		assert(false, "can not find sprite frame named: " .. spriteFrameName)
		return
	end

	local sprite = CCSprite:createWithSpriteFrame(spriteFrame)
	return sprite
end

function replaceSpriteWithSpriteFrame(sprite, spriteFrameName)
	if sprite == nil or spriteFrameName == nil then
		return
	end

	local spriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(spriteFrameName)
	if spriteFrame == nil then
		assert(false, "can not find sprite frame named: " .. spriteFrameName)
		return
	end

	sprite:setDisplayFrame(spriteFrame)
end

function replaceSpriteWithImage(sprite, imageName)
	if sprite == nil or imageName == nil then
		return
	end

	local texture = CCTextureCache:sharedTextureCache():addImage(imageName)
	if texture == nil then
		assert(false, "can not load image named: " .. imageName)
		return
	end

	sprite:setTexture(texture)
    local size = texture:getContentSize()
    local rect = CCRectMake(0, 0, size.width, size.height)
    sprite:setTextureRect(rect)
end

function setShadow(tf)
	local prop = tf:getTextDefinition()
	local anchorPos = tf:getAnchorPoint()
	if anchorPos.x == 0 then
		prop.m_alignment = ui.TEXT_ALIGN_LEFT
	elseif anchorPos.x == 0.5 then
		prop.m_alignment = ui.TEXT_ALIGN_CENTER 
	elseif anchorPos.x == 1 then
		prop.m_alignment = ui.TEXT_ALIGN_RIGHT 
	end

	if anchorPos.y == 0 then
		prop.m_vertAlignment = ui.TEXT_VALIGN_TOP 
	elseif anchorPos.y == 0.5 then
		prop.m_vertAlignment = ui.TEXT_VALIGN_CENTER  
	elseif anchorPos.y == 1 then
		prop.m_vertAlignment = ui.TEXT_VALIGN_BOTTOM 
	end

	local str = tf:getString()
	local newTF = ui.newTTFLabelWithShadow({
		text = str,
		font = prop.m_fontName,
		size = prop.m_fontSize,
		color = prop.m_fontFillColor,
		align = prop.m_alignment,
		valign = prop.m_vertAlignment,
		dimensions = prop.m_dimensions,
		shadowColor = ccc3(0, 0, 0),
		})
	newTF:setPosition(tf:getPosition())
	tf:setString("")
	tf:getParent():addChild(newTF)
	return newTF
end

--[[--

创建带阴影的 TTF 文字显示对象，并返回 CCLabelTTF 对象。

相比 ui.newTTFLabel() 增加一个参数：

-   shadowColor: 阴影颜色（可选），用 ccc3() 指定，默认为黑色

@param table params 参数表格对象

@return CCLabelTTF CCLabelTTF对象

]]
function ui.newTTFLabelWithShadow(params)
    assert(type(params) == "table",
           "[framework.ui] newTTFLabelWithShadow() invalid params")

    local color       = params.color or display.COLOR_WHITE
    local shadowColor = params.shadowColor or display.COLOR_BLACK
    local x, y        = params.x, params.y

    local g = display.newNode()
    params.size = params.size
    params.color = shadowColor
    params.x, params.y = 0, 0
    g.shadow1 = ui.newTTFLabel(params)
    local offset = 1 / (display.widthInPixels / display.width)
    g.shadow1:realign(offset, -offset)
    g:addChild(g.shadow1)

    params.color = color
    g.label = ui.newTTFLabel(params)
    g.label:realign(0, 0)
    g:addChild(g.label)

    function g:setString(text)
        g.shadow1:setString(text)
    	local offset = 1 / (display.widthInPixels / display.width)
    	g.shadow1:realign(offset, -offset)
        g.label:setString(text)
   	 	g.label:realign(0, 0)
    end

    function g:getString()
        return g.label:getString()
    end

    function g:realign(x, y)
        g:setPosition(x, y)
    end

    function g:getContentSize()
        return g.label:getContentSize()
    end

    function g:setColor(...)
        g.label:setColor(...)
    end

    function g:setShadowColor(...)
        g.shadow1:setColor(...)
    end

    function g:setOpacity(opacity)
        g.label:setOpacity(opacity)
        g.shadow1:setOpacity(opacity)
    end

    if x and y then
        g:setPosition(x, y)
    end

    return g
end

function cc.DrawNode:drawCircle(radius, params)
	local fillColor = cc.c4f(1,1,1,1)
	local borderColor = cc.c4f(1,1,1,1)
	local segments = 32
	local startRadian = 0
	local endRadian = math.pi*2
	local borderWidth = 0
	local posX = 0
	local posY = 0
	if params then
		if params.segments then segments = params.segments end
		if params.startAngle then
			startRadian = math.angle2Radian(params.startAngle)
		end
		if params.endAngle then
			endRadian = startRadian+math.angle2Radian(params.endAngle)
		end
		if params.fillColor then fillColor = params.fillColor end
		if params.borderColor then borderColor = params.borderColor end
		if params.borderWidth then borderWidth = params.borderWidth end
		if params.pos then
			posX =  params.pos[1]
			posY =  params.pos[2]
		end
	end
	local radianPerSegm = 2 * math.pi/segments
	local points = {}
	for i=1,segments do
		local radii = startRadian+i*radianPerSegm
		if radii > endRadian then break end
		table.insert(points, {posX + radius * math.cos(radii), posY + radius * math.sin(radii)})
	end
	self:drawPolygon(points, params)
	return self
end

QCCBAnimationProxy._release = QCCBAnimationProxy.release
function QCCBAnimationProxy:_release()
	scheduler.performWithDelayGlobal(function()
		self:_release()
	end, 0)
end
