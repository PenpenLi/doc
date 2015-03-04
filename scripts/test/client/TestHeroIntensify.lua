--
-- Author: Your Name
-- Date: 2014-08-12 16:36:14
--
describe["英雄强化页面测试"] = function ()
  	before = function()
    	printInfo('before')
  	end

  	after = function()
    	printInfo('after')
  	end

  	local hero_intensify_dialog
  	local select_hero_dialog
  	
  	it["选择英雄页面"] = function(done)
  		Promise()
  		:delay(1)
  		:and_then(function()
  			hero_intensify_dialog = app:getNavigationController():getTopDialog()
  			select_hero_dialog = hero_intensify_dialog._materialsBox[1]:_onTriggerTouch()
  		end)
  		:delay(1)
  		:and_then(function()
  			expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogHeroIntensifyMaterialSelection")
  			done()
  		end)
  		:done()
  	end
    
    local select_dialog
    
   	it["选择英雄"] = function(done)
   	local hero_frames
   		Promise()
   		:delay(1)
   		:and_then(function()
   		  select_dialog = app:getNavigationController():getTopDialog()
   			select_dialog:_changeHero(select_dialog._herosNativeID[1])
   		end)
		 :delay(1)
		 :and_then(capture)
		 :and_then(function()
		 	done()
		 end)
   		:done()
   	end

   	it["确认"] = function(done)
   		Promise()
   		:delay(1)
   		:and_then(function()
   			select_dialog:_onTriggerBtnConfirm()
   		end)
   		:delay(1)
		 :and_then(capture)
		 :and_then(function()
		 	done()
		 end)
   		:done()
   	end

  	it["自动添加"] = function(done)
  		Promise()
  		:delay(1)
  		:and_then(function()
  		    hero_intensify_dialog = app:getNavigationController():getTopDialog()
  			  hero_intensify_dialog:_onTriggerAutoAdd()
  		end)
  		:delay(1)
  		:and_then(capture)
  		:and_then(function()
  			done()
  		end)
  		:done()
  	end
 	
 	-- it["强化"] = function(done)
 	-- 	Promise()
 	-- 	:delay(1)
 	-- 	:and_then(function()
 	-- 		hero_intensify_dialog:_onTriggerStrengthen()
 	-- 	end)
 	-- 	:delay(1)
 	-- 	:and_then(capture)
 	-- 	:and_then(function()
 	-- 		done()
 	-- 	end)
 	-- 	:done()
 	-- end
 	  it["返回主界面"] = function(done)
 	  local dialog
 	    Promise()
 	    :delay(1)
 	    :and_then(function()
 	      hero_intensify_dialog:_onTriggerBack()
 	    end)
 	    :delay(1)
 	    :and_then(capture)
 	    :and_then(function()
 	      dialog = app:getNavigationController():getTopDialog()
 	      dialog:_onTriggerBack()
 	    end)
 	    :delay(1)
 	    :and_then(function()
 	      dialog = app:getNavigationController():getTopDialog()
 	      dialog:_onTriggerBack()
 	      done()
 	    end)
 	    :done()
 	  end

end