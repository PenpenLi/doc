--
-- 选区页面测试
-- Author: XuRui
-- Date: 2014-08-06
--
describe["选区页面测试"] = function ()
  before = function()
    printInfo('before')
  end

  after = function()
    printInfo('after')
  end

  local page_login
  local choose_dialog

      it["选区按钮"] = function(done)
        Promise()
        :delay(2)
        :and_then(function()
          page_login = app:getNavigationController():getTopPage()
          choose_dialog = page_login:onTouch({name = "began"})
        end)
        :delay(1)
        :and_then(function()
          expect(app:getNavigationController():getTopDialog().class.__cname).should_be("QUIDialogChooseServer")
          done()
        end)
        :done()
      end
      it["选择大区"] = function(done)
        Promise()
        :delay(1)
        :and_then(function()
          choose_dialog = app:getNavigationController():getTopDialog()
        end)
        :delay(1)
        :and_then(function()
          choose_dialog._boards[1]:onTouch({name = "began"})
          choose_dialog._boards[1]:onTouch({name = "moved"})
          choose_dialog._boards[1]:onTouch({name = "ended"})
          done()
        end)
        :done()
      end
  it["进入游戏"] = function(done)
    local main_menu_page
    Promise()
      :delay(2)
      :and_then(function()
        page_login = app:getNavigationController():getTopPage()
        main_menu_page = page_login:_onLogin()
      end)
      :delay(2)
      :and_then(capture)
      :and_then(function()
        expect("test").should_be("test")
        done()
      end)
      :done()
  end
--      it["注销"] = function(done)
--      local outlogin
--        Promise()
--        :delay(1)
--        :and_then(function()
--          page_login = app:getNavigationController():getTopPage()
--          outlogin = page_login:_onLogout()
--        end)
--        :delay(1)
--        :and_then(function()
--          expect(outlogin).should_be(app:getNavigationMidLayerController():getTopDialog())
--          outlogin:_onTriggerConfirm()
--          done()
--        end)
--        :done()
--      end
end
