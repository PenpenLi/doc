--
-- Author: Your Name
-- Date: 2014-08-08 16:49:02
--

describe[""] = function()
	before = function()
		printInfo('before')
	end
	after = function()
		printInfo('after')
	end
--  local QUIWidgetDivision = import("..widgets.QUIWidgetDivision")
	local arena_dialog
	local adj_dialog
	local team_arrangement_dialog
	local team_dialog

	it["进入调整队形页面"] = function(done)
	local adjust_dialog
		Promise()
		:delay(1)
		:and_then(function()
			arena_dialog = app:getNavigationController():getTopDialog()
			adjust_dialog = arena_dialog._heads[1]:_onChallenge()
		end)
		:delay(1)
		:and_then(function()
			expect(adjust_dialog).should_be(app:getNavigationController():getTopDialog())
			done() 
		end)
		:done()
	end

	it["移动角色1"] = function(done)
		 Promise()
		:delay(2)
		:and_then(function()
			adj_dialog = app:getNavigationController():getTopDialog()
			adj_dialog:_onTouch1({name = "began"})
			adj_dialog:_onTouch1({name = "moved",x = 500,y = 500})
			adj_dialog:_onTouch1({name = "ended",x = 500,y = 500})
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			done()
		end)
		:done()
	end
	
	it["调整队员"] = function(done)
	   Promise()
	   :delay(1)
	   :and_then(function()
	   	    adj_dialog:_onAdjustCrew()
	   end)
	   :delay(1)
	   :and_then(function()
	   		expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogTeamArrangement")
	   		done()
	   	end)
	   :done()
	end

	it["切换左侧tab"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
		  team_dialog = app:getNavigationController():getTopDialog()
			team_dialog:_onTriggerTabTank()
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
		  expect("test").should_be("test")
			done()
		end)
		:done()		
	end
	it["添加队员"] = function(done)
	local team_frames
	   Promise()
	   :delay(1)
	   :and_then(function()
	     team_frames = team_dialog._curPage:getHeroFrames()
	     team_frames[1]:_onTriggerHeroOverview()
	     end)
    :delay(1)
    :and_then(capture)
    :and_then(function()
      expect("test").should_be("test")
      done()
	   end)
	   :done()
	end
	it["返回调整队形"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			team_dialog:_onTriggerBack()
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
        expect("test").should_be("test")
			done()
		end)
		:done()
	end
--	it["开战"] = function(done)
--		Promise()
--		:delay(1)
--		:and_then(function()
--			adj_dialog:_onChallenge()
--		end)
--		:delay(1)
--		:and_then(capture)
--		:and_then(function()
--        expect("test").should_be("test")
--			done()
--		end)
--		:done()	
--	end

  it["返回主界面"] = function(done)
    local dialog
    Promise()
    :delay(1)
    :and_then(function()
      dialog = app:getNavigationController():getTopDialog()
      dialog:_onTriggerBack()
    end)
    :delay(1)
    :and_then(capture)
    :and_then(function()
       dialog = app:getNavigationController():getTopDialog()
       dialog:_onTriggerBack()
       done()
    end)
    :done()
  end
  
end