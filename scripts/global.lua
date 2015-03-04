--[[
全局定义的一些参数
--]]

global = {
    language = "chinese_simplified", -- localization
    title = "wow", -- global title

    -- 字体
    font_monaco = "Monaco.ttf",
    font_zhcn = "FZZhunYuan-M02S.ttf",

    -- 系统相关的参数
    system_reset_hour = 4, -- 每天凌晨4点重置所有的计数器，比如关卡能打的次数等

    ui_none_image = "ui/none.png", -- 1x1全透明的图片
    -- Drag Line
    ui_drag_line_white = "ui/white_line.png", -- 比较细的线
    ui_drag_line_green = "ui/green_line.png",  -- 比较粗的线
    ui_drag_line_yellow = "ui/yellow_line.png",  -- 比较粗的线
    ui_drag_line_circle = "ui/ball01.png", -- 线两端的圆
    -- Track Line
    ui_one_track_line = "effect/one_track_mind.png",  -- 一根经追踪线

    -- actor
    ui_actor_select_target = "ui/smallcircle_yellow.png",
    ui_actor_select_target_health = "ui/smallcircle_green.png",

    -- 界面相关的资源
    ui_hp_background_hero = "ui/hp_bg.png", -- 英雄的血条背景
    ui_hp_foreground_hero = "ui/hp_green.png", -- 英雄的血条
    ui_hp_background_npc = "ui/hp_bg.png", -- NPC的血条背景
    ui_hp_foreground_npc = "ui/hp_yellow.png", -- NPC的血条
    ui_hp_background_tmp = "ui/hp_red.png", -- 血条的临时背景，用于减血动画

    ui_skill_icon_placeholder = "ui/lock.png", -- 未开放的技能图标
    ui_skill_icon_effect_cding = "cding",  --技能图标正在CD的特效
    ui_skill_icon_effect_cdok = "cdok",  --技能图标CD完成的特效，后续自动接standby
    ui_skill_icon_effect_standby = "standby",  --技能图标可以点击的特效
    ui_skill_icon_effect_release = "release",  --技能图标释放的特效

    ui_hp_hide_delay_time = 3, -- 血条如果 x 秒内无变化则自行消失
    ui_hp_hide_fadeout_time = 0.4, -- 血条消失的时候淡出耗时

    ui_skill_icon_disabled_overlay = ccc3(63, 63, 63), -- 英雄技能图标CD状态中时所显示的颜色加成

    ui_hp_change_font_damage_npc = "font/YellowNumber.fnt",
    ui_hp_change_font_damage_hero = "font/RedNumber.fnt",   -- HP改变时的颜色：伤害
    ui_hp_change_font_treat = "font/GreenNumber.fnt",  -- HP改变时的颜色：治疗

    ui_dragline_color_no_target = ccc3(0, 235, 0),      -- 拖拽线目的地没有找到对象
    ui_dragline_color_on_enemy = ccc3(235, 235, 30),    -- 拖拽线指向敌人
    ui_dragline_color_on_teammate = ccc3(235, 235, 235),-- 拖拽线指向同伴

    ui_arena_start_aniamtion_ccbi = "ccb/Battle_SceneNumber.ccbi", -- 竞技场开始动画
    ui_battle_boss_animation_ccbi = "ccb/Battle_Widget_BossCome.ccbi", -- Boss出现的动画
    alliance_arena_flag_effect = "flag_alliance", -- 联盟旗
    horde_arena_flag_effect = "flag_horde", -- 部落旗
    attack_mark_effect = "hunter_mark", -- 集火特效

    loading_actor_file = "orc_warlord",
    loading_sheep_file = "sheep",
    loading_skeleton_animation_name = "walk02",

    hero_add_effect = "consecration_5_1", -- 新增英雄特效

    image_frame_wave_1 = "wave1.png",
    image_frame_wave_2 = "wave2.png",
    image_frame_wave_3 = "wave3.png",

    hero_enter_time = 3.5 - 1.0, -- 英雄进场时间，英雄需要在该时间内进场，NPC在这个时间后开始启动
    wave_animation_time = 2.5 - 1.0, -- 每一波开始前动画的时间
    boss_animation_time = 3.0, -- boss出现动画的时间

    movement_speed_min = 12, -- 移动速度的最小值

    -- 屏幕大区划分成3x5的区域
    screen_big_grid_width = 6,
    screen_big_grid_height = 4,

    -- 自定义的每个单位的像素数量
    pixel_per_unit = 64,
    ranged_attack_distance = 20, -- 如果攻击距离超过20个单位，则认为是远程攻击

    -- 屏幕上方和下方不可用区域，单位为屏幕操作单元格 18 x 10，单个格子的大小为pixel_per_unit
    screen_margin_top = 3.0,
    screen_margin_bottom = 2.5,
    screen_margin_left = 0.5,
    screen_margin_right = 0.5,

    -- 最大仇恨可追溯时间范围(秒)
    hatred_period = 10, 

    npc_view_dead_delay = 1.6,
    npc_view_dead_blink_time = 1.0,
    remove_npc_delay_time = 2.7,

    victory_animation_duration = 3,

    sao_dang_quan_id = 7,

    additions = {
        -- 增益和减益效果
        attack_value = 0, -- 攻击_数值 √
        attack_percent = 0, -- 攻击_百分比（%）√
        hp_value = 0, -- 生命值_数值 √
        hp_percent = 0, -- 生命值_百分比（%）√
        armor_physical = 0, -- 物理抗性（%）√
        armor_magic = 0, -- 法术抗性（%）√
        hit_rating = 0, -- 命中等级 √
        hit_chance = 0, -- 命中率（%）√
        dodge_rating = 0, -- 闪避等级 √
        dodge_chance = 0, -- 闪避率（%）√  
        block_rating = 0, -- 格挡等级 √
        block_chance = 0, -- 格挡率（%）√
        critical_rating = 0, -- 暴击等级 √  
        critical_chance = 0, -- 暴击率（%）√
        critical_damage = 0, -- 暴击伤害（%）√
        movespeed_value = 0, -- 移动速度_数值 √
        movespeed_percent = 0, -- 移动速度_百分比 √ 
        haste_rating = 0, -- 急速等级 
        attackspeed_chance = 0, -- 攻击速度百分比 
        physical_damage_percent_attack = 0, -- 物理伤害（%）√
        physical_damage_percent_beattack = 0, -- 物理易伤（%）√
        physical_damage_percent_beattack_reduce = 0, -- 物理伤害减免（%）√
        magic_damage_percent_attack = 0, -- 法术伤害（%）√
        magic_damage_percent_beattack = 0, -- 法术易伤（%）√
        magic_damage_percent_beattack_reduce = 0, -- 法术伤害减免（%）√
        magic_treat_percent_attack = 0, -- 治疗效果（%）√
        magic_treat_percent_beattack = 0, -- 被治疗效果（%）√
    },

    config = {
        energy_refresh_interval = 360,
        max_energy = 150,
        skill_refresh_interval = 300,
        max_skill = 10,
        max_battle_count = 3,

        dungeon_type_normal = 1,
        dungeon_type_advanced = 2,
        dungeon_difficult_easy = 1,
        dungeon_difficult_normal = 2,
        dungeon_difficult_hard = 3,

        award_type_money = 1,
        award_type_token_money = 2,
        award_type_team_exp = 3,
        award_type_exp = 4,
        award_type_item = 5,
        award_type_hero = 6,
    },

    --各种刷新时间合集
    freshTime = {
        map_freshTime = 4, --关卡次数的刷新时间
        buyEnergy_freshTime = 4, --购买体力的刷新时间
        buyMoney_freshTime = 4, --购买金钱的刷新时间
        silver_freshTime = 4, --银宝箱的刷新时间
        task_freshTime = 4, --银宝箱的刷新时间
        sginin_freshTime = 4, --签到的刷新时间
        sunwell_freshTime = 4, --太阳井的刷新时间
    },

    --解锁战队涉及关卡
    unlock_dungeon = {
        "wailing_caverns_8", --技能解锁
    },

    cutscenes = {
        KRESH_ENTRANCE = "KRESH_ENTRANCE",
    },

    -- 近战攻击在y轴上的最大攻击间隔
    melee_distance_y = 6,
}

global.font_default = global.font_zhcn