local QUIWidget = import("..widgets.QUIWidget")
local QUIWidgetVipClient = class("QUIWidgetVipClient", QUIWidget)

local vipContent = {
  VIP1 = {"累计充值$10$符石即可享受以下特权。\n","解锁装备强化之一键强化功能。\n","解锁使用符石扫荡关卡功能。\n","每天可免费领取扫荡劵$20$张。\n","每天可购买体力$2$次。\n","每天可使用点石成金$5$次。"},
  VIP2 = {"累计充值$100$符石即可享受以下特权。\n","包含$VIP1$等级所有特权。\n","解锁购买技能强化点数功能。\n","每天可免费领取扫荡劵$30$张。\n","每天可购买体力$3$次。\n","每天可使用点石成金$20$次。\n","每天可重置精英关卡$1$次。"},
  VIP3 = {"累计充值$300$符石即可享受以下特权。\n","包含$VIP2$等级所有特权。\n","解锁装备强化之全部强化功能。\n","解锁立即重置竞技场战斗CD功能。\n","每天可免费领取扫荡劵$40$张。\n","每天可购买体力$4$次。\n","每天可使用点石成金$30$次。\n","每天可重置精英关卡$2$次。\n","每天可购买竞技场门票$1$次。"},
  VIP4 = {"累计充值$500$符石即可享受以下特权。\n","包含$VIP3$等级所有特权。\n","解锁扫荡关卡之一键扫荡$10$次功能。\n","每天可免费领取扫荡劵$50$张。\n","每天可购买体力$5$次。\n","每天可使用点石成金$40$次。\n","每天可重置精英关卡$3$次。\n","每天可购买竞技场门票$2$次。"},
  VIP5 = {"累计充值$1000$符石即可享受以下特权。\n","包含$VIP4$等级所有特权。\n","解锁技能点上限增加至$20$点功能。\n","每天可免费领取扫荡劵$60$张。\n","每天可购买体力$6$次。\n","每天可使用点石成金$50$次。\n","每天可重置精英关卡$4$次。\n","每天可购买竞技场门票$3$次。"},
  VIP6 = {"累计充值$2000$符石即可享受以下特权。\n","包含$VIP5$等级所有特权。\n","每天可免费领取扫荡劵$70$张。\n","每天可购买体力$7$次。\n","每天可使用点石成金$60$次。\n","每天可重置精英关卡$5$次。\n","每天可购买竞技场门票$4$次。"},
  VIP7 = {"累计充值$3000$符石即可享受以下特权。\n","包含$VIP6$等级所有特权。\n","解锁装备附魔之一键附魔功能。\n","每天可免费领取扫荡劵$80$张。\n","每天可购买体力$8$次。\n","每天可使用点石成金$70$次。\n","每天可重置精英关卡$6$次。\n","每天可购买竞技场门票$5$次。"},
  VIP8 = {"累计充值$5000$符石即可享受以下特权。\n","包含$VIP7$等级所有特权。\n","每天可免费领取扫荡劵$90$张。\n","每天可购买体力$9$次。\n","每天可使用点石成金$80$次。\n","每天可重置精英关卡$7$次。\n","每天可购买竞技场门票$6$次。"},
  VIP9 = {"累计充值$7000$符石即可享受以下特权。\n","包含$VIP8$等级所有特权。\n","解锁永久召唤地精商人功能。\n","每天可免费领取扫荡劵$100$张。\n","每天可购买体力$10$次。\n","每天可使用点石成金$90$次。\n","每天可重置精英关卡$8$次。\n","每天可购买竞技场门票$7$次。"},
  VIP10 = {"累计充值$10000$符石即可享受以下特权。\n","包含$VIP9$等级所有特权。\n","解锁每天可重置决战太阳之井$2$次功能。\n","每天可免费领取扫荡劵$110$张。\n","每天可购买体力$11$次。\n","每天可使用点石成金$100$次。\n","每天可重置精英关卡$10$次。\n","每天可购买竞技场门票$8$次。"},
  VIP11 = {"累计充值$15000$符石即可享受以下特权。\n","包含$VIP10$等级所有特权。\n","解锁永久召唤黑市商人功能。\n","每天可免费领取扫荡劵$120$张。\n","每天可购买体力$12$次。\n","每天可使用点石成金$120$次。\n","每天可重置精英关卡$12$次。\n","每天可购买竞技场门票$9$次。"},
  VIP12 = {"累计充值$20000$符石即可享受以下特权。\n","包含$VIP11$等级所有特权。\n","每天可免费领取扫荡劵$130$张。\n","每天可购买体力$13$次。\n","每天可使用点石成金$150$次。\n","每天可重置精英关卡$15$次。\n","每天可购买竞技场门票$10$次。"},
  VIP13 = {"累计充值$40000$符石即可享受以下特权。\n","包含$VIP12$等级所有特权。\n","解锁决战太阳之井宝箱中金币奖励增加$50%$功能。\n","每天可免费领取扫荡劵$140$张。\n","每天可购买体力$14$次。\n","每天可使用点石成金$200$次。\n","每天可重置精英关卡$18$次。\n","每天可购买竞技场门票$11$次。"},
  VIP14 = {"累计充值$80000$符石即可享受以下特权。\n","包含$VIP13$等级所有特权。\n","每天可免费领取扫荡劵$150$张。\n","每天可购买体力$15$次。\n","每天可使用点石成金$250$次。\n","每天可重置精英关卡$21$次。\n","每天可购买竞技场门票$12$次。"},
  VIP15 = {"累计充值$150000$符石即可享受以下特权。\n","包含$VIP14$等级所有特权。\n","每天可免费领取扫荡劵$160$张。\n","每天可购买体力$16$次。\n","每天可使用点石成金$300$次。\n","每天可重置精英关卡$25$次。\n","每天可购买竞技场门票$13$次。"},
}

function QUIWidgetVipClient:ctor(options)
  local ccbFile = "ccb/Widget_Vip.ccbi"
  local callBacks = {}
  QUIWidgetVipClient.super.ctor(self, ccbFile, callBacks, options)

  self:setVipContent(options.vip)
end

function QUIWidgetVipClient:setVipContent(vip)
  for i = 1, #vipContent[vip], 1 do
    self:setMoreColorLabel(vipContent[vip][i], i)
  end
end

function QUIWidgetVipClient:setMoreColorLabel(str, row)
  local content = string.split(str, "$")
  local label1 = CCLabelTTF:create()
  label1:setFontSize(24)
  label1:setAnchorPoint(ccp(0, 1))
  label1:setFontName("font/FZZhunYuan-M02S.ttf")
  local label2 = CCLabelTTF:create()
  label2:setFontSize(24)
  label2:setAnchorPoint(ccp(0, 1))
  label2:setFontName("font/FZZhunYuan-M02S.ttf")
  local label3 = CCLabelTTF:create()
  label3:setFontSize(24)
  label3:setAnchorPoint(ccp(0, 1))
  label3:setFontName("font/FZZhunYuan-M02S.ttf")
  
  if string.find(content[1], "解锁") then
      label1:setColor(ccc3(255, 168, 44))
    else
      label1:setColor(ccc3(255, 232, 191))
  end
  label1:setString(content[1])
  
  if content[2] ~= nil then
    if string.find(content[1], "解锁") then
      label3:setColor(ccc3(255, 168, 44))
    else
      label3:setColor(ccc3(255, 232, 191))
    end
    label2:setString(content[2])
    label2:setColor(ccc3(255, 255, 255))
    label3:setString(content[3])
  end
  label2:setPosition(ccp(label1:getContentSize().width, 0))
  label3:setPosition(ccp(label1:getContentSize().width + label2:getContentSize().width, 0))
  local rowNode = CCNode:create()
  rowNode:addChild(label1)
  rowNode:addChild(label2)
  rowNode:addChild(label3)
  rowNode:setAnchorPoint(ccp(0, 1))
  rowNode:setPosition(ccp(0, -(28 * (row - 1))))
  self._ccbOwner.content_node:addChild(rowNode)
end

function QUIWidgetVipClient:getContentSize()
  return 300
end

return QUIWidgetVipClient
