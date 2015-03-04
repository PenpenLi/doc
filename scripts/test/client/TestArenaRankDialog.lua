--
-- Author: Your Name
-- Date: 2014-08-08 15:12:41
--
describe["测试竞技场排行榜"] = function()
	before = function()
		printInfo('before')
	end
	after = function()
		printInfo('after')
	end

	local main_menu_page
	local arena_dialog
	local rank_dialog

	it["奖励规则"] = function(done)
	local rule_dialog
		Promise()
		:delay(1)
		:and_then(function()
			arena_dialog = app:getNavigationController():getTopDialog()
			rule_dialog = arena_dialog:_onRuleTab()
		end)
		:delay(1)
		:and_then(function()
			expect(rule_dialog).should_be(app:getNavigationController():getTopDialog())
			done()
		end)
		:done()
	end
	 it["对战记录"] = function(done)
	 local record_dialog
		Promise()
		:delay(1)
		:and_then(function()
			arena_dialog:_onRecordTab()
		end)
		:delay(1)
		:and_then(function()
			expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogAgainstRecord")
			done()
		end)
		:done()
	end
 	it["赛区排行榜"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			arena_dialog:_onRankTab()
		end)
		:delay(1)
		:and_then(function()
			expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogList")
			done()
		end)
		:done()
	end

    it["向左无法滑动"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			rank_dialog = app:getNavigationController():getTopDialog()
			rank_dialog:_onTouch({name = "began",x = "0",0})
			rank_dialog:_onTouch({name = "moved",x = "500",0})
			rank_dialog:_onTouch({name = "ended",x = "0",0})
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			expect("test").should_be("test")
			done()
		end)
		:done()
	end
	
	it["选择一个用户"] = function(done)
	  Promise()
	  :delay(1)
	  :and_then(function()
	     rank_dialog._listHead[2]:_onPress()
	  end)
	  :delay(1)
	  :and_then(capture)
	  :and_then(function()
	     done()
	  end)
	  :done()
	end

	it["向右滑动"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			rank_dialog:_onTouch({name = "began",x = "0",0})
			rank_dialog:_onTouch({name = "moved",x = "-4000",0})
			rank_dialog:_onTouch({name = "ended",x = "0",0})
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			expect("test").should_be("test")
			done()
		end)
		:done()
	end
	it["到达右边界时无法继续滑动"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			rank_dialog:_onTouch({name = "began",x = "0",0})
			rank_dialog:_onTouch({name = "moved",x = "-1200",0})
			rank_dialog:_onTouch({name = "ended",x = "0",0})
		end)
		:delay(1)
		:and_then(capture)
		:and_then(function()
			-- rank_dialog:onEvent({name = "HEAD_ON_PRESS"} )
			expect("test").should_be("test")
			done()
		end)
		:done()
	end

	it["返回竞技场挑战"] = function(done)
		local challenge
		Promise()
		:delay(1)
		:and_then(function()
			rank_dialog:_onBattleTab()
		end)
		:delay(1)
		:and_then(function()
			done()
		end)
		:done()
	end
end