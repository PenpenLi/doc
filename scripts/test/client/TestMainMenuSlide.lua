-- 测试主场景能否被滑动
describe["测试主场景能否被滑动"] = function()
    before = function()
        printInfo('before')
    end

    after = function()
        printInfo('after')
    end

    it["通过手指滑动主屏到右边"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :delay(2)
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "-300",0})
            mainmenu:_onTouch({name = "ended",x = "-300",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            expect("test").should_be("test")
            done()
        end)
        :done()
    end

    it["滑动到右边后不能再滑动"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "-300",0})
            mainmenu:_onTouch({name = "ended",x = "-300",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            done()
        end)
        :done()
    end

    it["通过手指滑动主屏还原"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "900",0})
            mainmenu:_onTouch({name = "ended",x = "900",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            done()
        end)
        :done()
    end

    it["通过手指滑动主屏到左边"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "900",0})
            mainmenu:_onTouch({name = "ended",x = "900",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            done()
        end)
        :done()
    end

    it["滑动到左边后不能再滑动"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "900",0})
            mainmenu:_onTouch({name = "ended",x = "900",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            done()
        end)
        :done()
    end
    
    it["通过手指滑动主屏还原"] = function(done)
        local mainmenu = app:getNavigationController():getTopPage()

        Promise()
        :and_then(function()
            mainmenu:_onTouch({name = "began",x = "300",0})
            mainmenu:_onTouch({name = "moved",x = "-300",0})
            mainmenu:_onTouch({name = "ended",x = "-300",0})
        end)
        :delay(1)
        :and_then(capture)
        :and_then(function()
            done()
        end)
        :done()
    end
end