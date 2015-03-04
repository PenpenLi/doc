--
-- Author: Your Name
-- Date: 2014-08-12 09:49:51
--
describe["英雄信息页面测试"] = function ()
  	before = function()
    	printInfo('before')
  	end

  	after = function()
    	printInfo('after')
  	end

  	local hero_info_dialog
  	local skill_dialog
  	local hero_dialog

  	it["显示装备信息"] = function(done)
  	local eqp_info
  		Promise()
  		:delay(1)
  		:and_then(function()
  			 hero_info_dialog = app:getNavigationController():getTopDialog()
  			 eqp_info = hero_info_dialog._equipBox[2]:_onTriggerTouch()
  		end)
  		:delay(1)
  		:and_then(capture)
  		:and_then(function()
  		  local equipment_dialog = app:getNavigationMidLayerController():getTopDialog()
  		  if equipment_dialog ~=nil and equipment_dialog.class.__cname == "QUIDialogItemDropInfo" then 
  		    equipment_dialog:_onTriggerClose()
  		  end
  			done()
  		end)
  		:done()
  	end

  	it["英雄详细资料"] = function(done)
  	local introduce
		Promise()
		:delay(1)
		:and_then(function()
			introduce = hero_info_dialog:_onDetailData()
		end)
		:delay(1)
		:and_then(function()
			expect(introduce).should_be(true)
			done()
		end)
		:done()
	end
  it["图鉴"] = function(done)
   local hero_card
    Promise()
    :delay(1)
    :and_then(function()
      hero_info_dialog:_onHeroCard()
    end)
    :delay(1)
    :and_then(capture)
    :and_then(function()
      hero_info_dialog._card:_onTriggerClick()
      done()
    end)
    :done()
  end
  it["关闭大图"] = function(done)
    local big_card
    Promise()
    :delay(1)
    :and_then(function()
      big_card = app:getNavigationMidLayerController():getTopDialog()
      if big_card ~= nil and big_card.class.__cname == "QUIDialogHeroCard" then 
        big_card:_onTriggerClose()
      end
      done()
    end)
    :done()
  end
	it["向左选择"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			hero_info_dialog:_onTriggereLeft()
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			done()
		end)
		:done()
	end
	it["向右选择"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			hero_info_dialog:_onTriggereRight()
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			done()
		end)
		:done()
	end

	it["突破"] = function(done)
		local strike_dialog
		Promise()
		:delay(1)
		:and_then(function()
			strike_dialog = hero_info_dialog:_onStrike()
		end)
		:delay(1)
		:and_then(function()
			expect(strike_dialog).should_be(app:getNavigationController():getTopDialog())
			strike_dialog = app:getNavigationController():getTopDialog()
			strike_dialog:_onTriggerClose()
			done()
		end)
		:done()
	end

	it["进阶"] = function(done)
 	local advance_dialog
		Promise()
		:delay(1)
		:and_then(function()
			advance_dialog = hero_info_dialog:_onAdvance()
		end)
		:delay(1)
		:and_then(function()
			expect(advance_dialog).should_be(app:getNavigationController():getTopDialog())
			advance_dialog = app:getNavigationController():getTopDialog()
			advance_dialog:_onTriggerClose()
			done()
		end)
		:done()
	end

	it["技能升级"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			skill_dialog = hero_info_dialog:_onSkillStrengthen()
		end)
		:delay(1)
		:and_then(function()
			expect(skill_dialog).should_be(app:getNavigationController():getTopDialog())
			done()
		end)
		:done()
	end
	
	it["选择技能"] = function(done)
	   Promise()
	   :delay(1)
	   :and_then(function()
	     skill_dialog.strength_skill2:_onTriggerClick()
     end)
     :delay(1)
     :and_then(capture)
     :and_then(function()
        skill_dialog.special_skill:_onTriggerClick()
     end)
     :delay(1)
     :and_then(capture)
     :and_then(function()
        skill_dialog:_onTriggerBack()
        done()
	   end)
	   :done()
	end
	
--	it["升级按钮"] = function(done)
--		Promise()
--		:delay(1)
--		:and_then(function()
--			skill_dialog:_onTriggerUpgradeHandler()
--		end)
--		:delay(1)
--		:and_then(capture)
--		:and_then(function()
--		  skill_dialog:_onTriggerBack()
--			done()
--		end)
--		:done()
--	end

	  it["英雄强化"] = function(done)
	  	Promise()
	  	:delay(1)
	  	:and_then(function()
	  		hero_dialog = hero_info_dialog:_onHeroStrengthen()
	  	end)
	  	:delay(1)
	  	:and_then(function()
	  		expect(hero_dialog).should_be(app:getNavigationController():getTopDialog())
	  		done()
	  	end)
	  	:done()
	  end
end