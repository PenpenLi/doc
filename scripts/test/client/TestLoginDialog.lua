--
-- 测试登陆是否正常
-- Author: XuRui
-- Date: 2014-08-05 12:32:08
--
describe["测试登陆是否正常"] = function ()
  before = function()
    printInfo('before')
  end

  after = function()
    printInfo('after')
  end

  local loginDialog
  local registerDialog

  it["切换注册页面"] = function (done)
    Promise()
      :delay(2)
      :and_then(function ()
        loginDialog = app:getNavigationController():getTopDialog()
        registerDialog = loginDialog:onRegister()
      end)
      :delay(1)
      :and_then(function()
        expect(registerDialog).should_be(app:getNavigationController():getTopDialog())
        done()
      end)
      :done()
  end
  it["切换登录界面"] = function (done)
    local gamelogin
    local user = "test"
    local pass = "123"
    loginDialog = app:getNavigationController():getTopDialog()
    Promise()
      :delay(2)
      :and_then(function ()
        gamelogin = loginDialog:onGameLogin()
      end)
      :delay(1)
      :and_then(function()
        gamelogin._edit1:setText(user)
        gamelogin._edit2:setText(pass)
        expect(gamelogin).should_be(app:getNavigationController():getTopDialog())
        done()
      end)
      :done()
  end

  it["是否记住密码"] = function (done)
    local remember
    loginDialog = app:getNavigationController():getTopDialog()
    Promise()
      :and_then(function ()
        remember = loginDialog:onRemember()
        done()
      end)
      :done()
  end

  it["登录"] = function (done)
    local touch
    Promise()
      :delay(1)
      :and_then(function ()
        touch = loginDialog:onLogin()
        done()
      end)
      :delay(1)
      :and_then(capture)
      :done()
  end
end
