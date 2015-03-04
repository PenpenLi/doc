--
-- Author: Xurui
-- Date: 2014-08-08 09:49:57
--
describe["测试竞技场"] = function()
	before = function()
		printInfo('before')
	end
	after = function()
		printInfo('after')
	end

	local main_menu_page
	local arena_dialog
	local rank_dialog

	it["进入竞技场"] = function(done)
		Promise()
		:delay(2)
		:and_then(function()
			main_menu_page = app:getNavigationController():getTopPage()
			main_menu_page._pressTime = 1
			main_menu_page:_onArena()
		end)
		:delay(1)
		:and_then(function()
			done()
		end)
		:done()
	end

	it["换一批按钮"] = function(done)
		Promise()
		:delay(1)
		:and_then(function()
			arena_dialog = app:getNavigationController():getTopDialog()
			arena_dialog:_onReplace()
		end)	
		:delay(1)
		:and_then(capture)
		:and_then(function()
			expect("test").should_be("test")
			done()
		end)
		:done()
	end
end