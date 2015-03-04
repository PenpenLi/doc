pcall(require, "luacov")    --measure code coverage, if luacov is present
require("test.luaspec") -- lua spec测试支持
require("test.AndThen") -- lua promise支持

-- 引用测试集
is_in_test = true

-- require("test.client.TestLoginDialog")           --登录
-- require("test.client.TestRegisterDialog")        --注册
-- require("test.client.TestPageLogin")             --选择服务器进入游戏
-- require("test.client.TestSideMenu")              --侧边栏英雄按钮
-- require("test.client.TestHeroInformation")       --进入英雄详细信息页面
-- require("test.client.TestHeroIntensify")         --英雄强化
-- require("test.client.TestMainMenuSlide")         --主页面滑动
-- require("test.client.TestArenaDialog")           --竞技场
-- require("test.client.TestArenaRankDialog")       --竞技场排行榜
-- require("test.client.TestAdjustDialog")          --调整阵型
-- require("test.client.TestUserHeadClick")         --主页面点击头像
-- require("test.client.TestInstance")              --副本
-- require("test.client.TestBuyVirtual")            --购买金钱和体力
-- require("test.client.TestTreasureChestDraw")     --宝箱抽卡
-- require("test.client.TestMail")                  --邮箱
-- require("test.client.TestSideMenuTeam")          --侧边栏阵容按钮
