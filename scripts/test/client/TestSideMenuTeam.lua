--
-- Author: Your Name
-- Date: 2014-08-13 14:27:57
--
describe["侧边栏阵容测试"] = function ()
  	before = function()
    	printInfo('before')
  	end

  	after = function()
    	printInfo('after')
  	end

  	local main_menu_page

  	it["打开侧边栏"] = function(done)
  	    Promise()
  		:delay(1)
  		:and_then(function()
  		main_menu_page = app:getNavigationController():getTopPage()
  		main_menu_page._scaling:_onTouch({name ="began"})
  		done()
  	end)
  	:delay(1)
  	:and_then(capture)
  	:and_then(function()
  		done()
  	end)
  	:done()
  	end

    local team_dialog

  	it["打开阵容页面"] = function(done)
  		Promise()
  		:delay(1)
  		:and_then(function()
  			team_dialog = main_menu_page._scaling:_onButtondownSideMenuTeam()
  		end)
  		:delay(1)
  		:and_then(function()
  			expect(team_dialog).should_be(app:getNavigationController():getTopDialog())
  			done()
  		end)
  		:done()
  	end
  	it["选择英雄"] = function(done)
  	 Promise()
  	 :delay(1)
  	 :and_then(function()
        team_dialog:_addHeroToTeam(team_dialog._herosID[1])
  	 end)
  	 :delay(1)
  	 :and_then(capture)
  	 :and_then(function()
  	   done()
  	 end)
  	 :done()
  	end
  	it["关闭阵容界面"] = function(done)
       Promise()
      :delay(1)
      :and_then(function()
        team_dialog:_onTriggerBack()
    end)
    :delay(2)
    :and_then(capture)
    :and_then(function()
      done()
      os.exit()
    end)
    :done()
    end
    
    
    
end