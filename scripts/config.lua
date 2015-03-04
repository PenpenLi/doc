
LOAD_DEPRECATED_API = true               -- 在框架初始化时载入过时的 API 定义
USE_DEPRECATED_EVENT_ARGUMENTS = true    -- 使用过时的事件回调参数
DISABLE_DEPRECATED_WARNING = false       -- true: 不显示过时 API 警告，false: 要显示警告

require("global")
require("version")
require("buildTime")

-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 1
DEBUG_FPS = true
DEBUG_MEM = false
DEBUG_NETWORK = true

CONFIG_SCREEN_AUTOSCALE = "FIXED_WIDTH"

-- battle resolution
BATTLE_SCREEN_WIDTH  = 1280
BATTLE_SCREEN_HEIGHT = 720

-- ui resolution
UI_DESIGN_WIDTH = 1136
UI_DESIGN_HEIGHT = 640

-- screen resolution
CONFIG_SCREEN_WIDTH  = 1136
CONFIG_SCREEN_HEIGHT = 640

-- scaling range
CONFIG_SCALE_MIN = 960/640  -- Iphone 4S   
CONFIG_SCALE_MAX = 2208/1242 -- Iphone 6 plus

-- debug config
DISPLAY_ACTOR_RECT = false
DISPLAY_ACTOR_CORE_RECT = false
DISPLAY_ACTOR_MOVE = false     -- 显示人物移动的目的地和路径
DISPLAY_PROPERTY_GRID = false  -- 显示屏幕站位网格
DISPLAY_SKILL_RANGE = false -- 显示群体技能的攻击范围(显示为椭圆范围的外接矩形)
DISPLAY_TRAP_RANGE = false -- 显示陷阱的影响范围(显示为椭圆范围的外接矩形)
CHECK_SKELETON_FILE = false -- 检查spine的导出文件是否有效

SKIP_TUTORIAL = false -- 是否跳过新手引导
TUTORIAL_WORD_TIME = 1 -- 新手引导对话框延迟时间
TUTORIAL_ONEWORD_TIME = 0.05 --新手引导打字机打字速度
ONLY_BATTLE_TUTORIAL = true -- 是否只运行战斗部分的引导（首次战斗新手引导，第一关引导使用剑刃风暴，第二关引导攻击毒蛇）
CAN_SKIP_BATTLE = false

UNLOCK_DELAY_TIME = 3   --解锁提示消失的延迟时间

-- ui config:true翻页、false滑动
MAIN_MENU_DRAG_PAGE = false

-- actor config
ENABLE_ACTOR_RENDER_TEXTURE = false
DISPLAY_HIT_ANIMATION = true
DEBUG_DAMAGE = false
SKIP_BATTLE_SOUND = false

-- client mode
GAME_MODE = 1
EDITOR_MODE = 2
CURRENT_MODE = QUtility:getLaunchMode()
if CURRENT_MODE == EDITOR_MODE then
    -- DEBUG_FPS = false
    require("arenadatabase")
end

ENVIRONMENT = {
    LOCAL = {
        CHANNEL_NAME = "local",
        SERVER_URL = "192.168.0.69:8080",
        STATIC_URL = "http://static.xmoshou.com/staging/"
    },
    staging = {
        CHANNEL_NAME = "staging",
        SERVER_URL = "ws://staging.xmoshou.com:8080/api/v1",
        STATIC_URL = "http://static.xmoshou.com/staging/"
    },
    develop = {
        CHANNEL_NAME = "develop",
        SERVER_URL = "ws://beta-center.xmoshou.com:8080/api/v1",
        STATIC_URL = "http://static.xmoshou.com/beta/"
    },
    dev_ui = {
        CHANNEL_NAME = "dev_ui",
        SERVER_URL = "dev-ui.xmoshou.com:9080",
        STATIC_URL = "http://static.xmoshou.com:80/dev-ui/"
    },
    dev_fight = {
        CHANNEL_NAME = "dev_fight",
        SERVER_URL = "ws://dev-fight.xmoshou.com:10080/api/v1",
        STATIC_URL = "http://static.xmoshou.com:80/dev-fight/"
    },
    beta = {
        CHANNEL_NAME = "内部测试",
        SERVER_URL = "beta-center.xmoshou.com:8080",
        STATIC_URL = "http://static.xmoshou.com/beta/"
    },
    release = {
        CHANNEL_NAME = "开放测试",
        SERVER_URL = "prod-center.xmoshou.com:80",
        STATIC_URL = "http://static.xmoshou.com:80/prod/"
    },
    release_dispense = {
        CHANNEL_NAME = "自分发测试",
        SERVER_URL = "prod-center.xmoshou.com:80",
        STATIC_URL = "http://static.xmoshou.com:80/prod-dispense/"
    },
    release_TongBuTui = {
        CHANNEL_NAME = "同步推",
        SERVER_URL = "http://tongbu-center.xmoshou.com/api/v1",
        STATIC_URL = "http://static.xmoshou.com:80/tongbu/"
    },
    
}

local envName = require("environment")
-- 开发版本用beta的服务器
if envName == "" then
    envName = "dev_ui"
end

if envName == "release" or envName == "release_TongBuTui" or envName == "release_dispense" then
    DEBUG = 0
    DEBUG_FPS = false
    DEBUG_MEM = false
    DEBUG_NETWORK = false
    DEBUG_DAMAGE = false
end

print("[Environment]" .. envName)
CHANNEL_NAME = ENVIRONMENT[envName]["CHANNEL_NAME"]
SERVER_URL = ENVIRONMENT[envName]["SERVER_URL"]
STATIC_URL = ENVIRONMENT[envName]["STATIC_URL"]

INFO_APP_UDID = QUtility:getAppUUID()
INFO_PLATFORM = QUtility:getPlatform()
INFO_SYSTEM_VERSION = QUtility:getSystemVersion()
INFO_SYSTEM_MODEL = QUtility:getSystemModel()

print(INFO_APP_UDID)
print(INFO_PLATFORM)
print(INFO_SYSTEM_VERSION)
print(INFO_SYSTEM_MODEL)

BATTLE_AREA = {
    left = global.screen_margin_left * global.pixel_per_unit,
    bottom = global.screen_margin_bottom * global.pixel_per_unit,
    width = BATTLE_SCREEN_WIDTH - (global.screen_margin_right + global.screen_margin_left) * global.pixel_per_unit,
    height = BATTLE_SCREEN_HEIGHT - global.screen_margin_top * global.pixel_per_unit - global.screen_margin_bottom * global.pixel_per_unit,
}

BATTLE_AREA.right = BATTLE_AREA.left + BATTLE_AREA.width
BATTLE_AREA.top = BATTLE_AREA.bottom + BATTLE_AREA.height

EPSILON = 0.1
HIT_DELAY = 0.3
HIT_DELAY_FRAME = 10.0
SPINE_RUNTIME_FRAME = 30.0

-- 人物类型
ACTOR_TYPES = {
    HERO = "ACTOR_TYPE_HERO",
    HERO_NPC = "ACTOR_TYPE_HERO_NPC",
    NPC = "ACTOR_TYPE_NPC", 
}

QDEF = {
    -- readable return value
    HANDLED = "HANDLED",

    -- ui constants
    SCALE_CLICK = 1.05,

    -- events
    EVENT_CD_CHANGED = "EVENT_CD_CHANGED",
    EVENT_CD_STARTED = "EVENT_CD_STARTED",
    EVENT_CD_STOPPED = "EVENT_CD_STOPPED",
}

ANIMATION = {
    WALK = "walk",
    REVERSEWALK = "reverse-walk",
    STAND = "stand",
    ATTACK = "attack",
    HIT = "hit",
    SELECTED = "selected",
    DEAD = "dead",
    VICTORY = "victory",
}

ANIMATION_EFFECT = {
    VICTORY = "common_victory",
    WALK = "common_walk",
}

ROOT_BONE = "root"

DUMMY = {
    -- free dummy
    TOP = "dummy_top",
    CENTER = "dummy_center",
    BOTTOM = "dummy_bottom",
    -- move with animation
    BODY = "dummy_body",
    WEAPON = "dummy_weapon",
    HEAD = "dummy_head",
    FOOT = "dummy_foot",
    LEFT_HAND = "dummy_left_hand",
    RIGHT_HAND = "dummy_right_hand",
}

--装备类型
EQUIPMENT_TYPE = {
    WEAPON = "weapon",
    HAT = "hat",
    CLOTHES = "clothes",
    BRACELET = "bracelet",
    SHOES = "shoes",
    JEWELRY = "jewelry"
}

--装备品质
EQUIPMENT_QUALITY = {
    "white",
    "green",
    "blue",
    "purple",
    "orange"
}

ITEM_QUALITY_INDEX = {
    WHITE = 1,
    GREEN = 2,
    BLUE = 3,
    PURPLE = 4,
    ORANGE = 5
}

--装备品质
EQUIPMENT_COLOR = {
    ccc3(255,255, 255), -- white
    ccc3(81,255, 0), -- green
    ccc3(41,208, 243), --blue
    ccc3(237,0, 239), --purple
    ccc3(255,156, 0) --orange
}

--英雄突破 breakthrough
BREAKTHROUGH_COLOR = {
    green = ccc3(88, 243, 41), -- green
    blue = ccc3(41, 208, 243), -- blue
    purple = ccc3(214, 40, 233), --purple
}

--item类型
ITEM_TYPE = {
    MONEY = "money",
    TOKEN_MONEY = "token",
    ARENA_MONEY = "arena_money",
    SUNWELL_MONEY = "sunwell_money",
    ENERGY = "energy",
    ITEM = "item",
    HERO = "hero",
    TEAM_EXP = "team_exp",
    ACHIEVE_POINT = "achieve_point",
}

--item分类
--[[
    1为装备碎片 
    2为装备 
    3为英雄碎片 
    4为消耗品
]]
ITEM_CATEGORY = {
    SCRAP = 1, -- 装备碎片
    EQUIPMENT = 2, -- 装备
    SOUL = 3, -- 灵魂碎片
    CONSUM = 4, -- 消耗品
    CONSUM_MONEY = 5, -- 卖钱的消耗品
}

ICON_URL = {
    MONEY = "icon/item/gold2.png",
    ITEM_MONEY = "icon/item/gold.png",
    TOKEN_MONEY = "icon/item/fushi2.png",
    ITEM_TOKEN_MONEY = "icon/item/fushi.png",
    ARENA_MONEY = "icon/item/arena_gold2.png",
    SUNWELL_MONEY = "icon/item/sunwell.png",
    ITEM_ARENA_MONEY = "icon/item/arena_gold.png",
    ENERGY = "icon/item/tili2.png",
    ITEM_ID_3 = "icon/item/quanshui2.png",
    ITEM_ID_4 = "icon/item/milk2.png",
    ITEM_ID_5 = "icon/item/fengbao2.png",
    ITEM_ID_6 = "icon/item/boerduo2.png",
    TEAM_EXP = "icon/item/sheet_small_exp.png",
    ACHIEVE_POINT = "icon/item/icon_achievement.png",
}

--道具ID
ITEM_ID = {
    CRYSTAL = "1",  --奥数水晶
}

--进阶的最高级
GRAD_MAX = 4

--副本类型
DUNGEON_TYPE = {
    NORMAL = 1,
    ELITE = 2,
    ACTIVITY_TIME = 3,
    ACTIVITY_CHALLENGE = 4,
    ALL = 3,
}

BATTLE_MODE = {
    CONTINUOUS = 1,
    SEVERAL_WAVES = 2,
    WAVE_WITH_DIFFERENT_BACKGROUND = 3
}

--完成事件
EVENT_COMPLETED = "Completed"

EFFECT_ANIMATION = "animation"

--推送通知
NOTIFICATION_12 = "12:00 午间能量豪礼大放送~继续愉快的玩耍起来吧~"
NOTIFICATION_18 = "18:00 晚间能量豪礼大放送~英雄们都跃跃欲试了呢！"
NOTIFICATION_21 = "21:00 深夜能量豪礼大放送~快来游戏战个痛！"
NOTIFICATION_ENERGY_RECOVERED = "体力全部回复满了~英雄快来继续远征吧~"
NOTIFICATION_SKILL_RECOVERED = "技能点全部回复满了~快来给英雄们提高战斗力吧！"


--[[
英雄入场起始点:
位置示意图:
        3
       / \
      4   1
       \ /     
        2  
坐标系:
        ↑y
        |
    ---------→ x
        |
        |
格式:
{{x, y}, {x, y}, {x, y}, {x, y}}
x和Y是指离屏幕中心的偏移
--]] 

HERO_POS = {{30, 0}, {-118, -100}, {-158, 100}, {-316, 0}}
ARENA_HERO_POS = {{-80, 0}, {-194, -120}, {-268, 120}, {-412, 0}}
