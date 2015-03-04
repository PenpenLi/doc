--点击头像事件测试
describe["点击头像事件测试"] = function()
    before = function()
        printInfo('before team')
    end

    after = function()
        printInfo('after team')
    end
    
    local main_menu_page
    local rank_page
    
    it["显示军衔页面"] = function (done)
    Promise()
    :delay(1)
    :and_then(function ()
      main_menu_page = app:getNavigationController():getTopPage()
      rank_page = main_menu_page:_onUserHeadClickHandler()
    end)
    :delay(1)
    :and_then(function ()
        expect(rank_page).should_be(app:getNavigationController():getTopDialog())
      done()
    end)
    :done()
    end
    
    it["无法向上滑动军衔选择条"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        rank_page = app:getNavigationController():getTopDialog()
        rank_page:_onEvent({name = "EVENT_SLIDE_GESTURE", distance = {y = -400}})
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test")
        done()
      end)
      :done()
    end

    it["向下滑动军衔选择条"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        rank_page = app:getNavigationController():getTopDialog()
        rank_page:_onEvent({name = "EVENT_SLIDE_GESTURE", distance = {y = 2400}})
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test")
        done()
      end)
      :done()
    end
    it["滑动军衔选择条到底部后无法再进行滑动"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        rank_page = app:getNavigationController():getTopDialog()
        rank_page:_onEvent({name = "EVENT_SLIDE_GESTURE", distance = {y = 400}})
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test")
        done()
      end)
      :done()
    end
    
    it["去往竞技场页面"] = function (done)
    local arena_page
      Promise()
      :delay(1)
      :and_then(function()
        rank_page = app:getNavigationController():getTopDialog()
        rank_page:_onTriggerGotoArena()
      end)
      :delay(1)
      :and_then(function()
        done()
      end)
      :done()
    end
    
--    it["去往排行榜页面"] = function (done)
--    local division_page
--      Promise()
--      :delay(1)
--      :and_then(function()
--        rank_page = app:getNavigationController():getTopDialog()
--        division_page = rank_page:_onTriggerGotoArena()
--      end)
--      :delay(1)
--      :and_then(function()
--        expect(division_page).should_be(app:getNavigationController():getTopDialog())
--        division_page:_onTriggerBack()
--        done()
--      end)
--      :done()
--    end
--    
    it["返回主页面"] = function(done)
      Promise()
      :delay(1)
      :and_then(function()
        rank_page = app:getNavigationController():getTopDialog()
        main_menu_page = rank_page:_onTriggerBack()
      end)
      :delay(1)
      :and_then(capture)
      :and_then(function()
        done()
      end)
      :done()
    end
    
end