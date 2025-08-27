X-开始场景:
	X-标题
	X-游戏开始按钮
	X-选项按钮
	X-游戏图鉴按钮
	X-游戏统计按钮
	X-使用虚拟鼠标实现不同场景图片切换
	X-游戏音乐 & 音效

V-游戏场景
	V-战斗区域
		V-从商店将棋子拖动(左键点击, 右键放下, Esc取消)到战斗区域或等待区域视为购买棋子, 花费特定数量金币;
		X-将棋子从战斗区域或等待区域拖动到商店区域视为出售棋子, 获得特定数量金币;
		X-战斗区域可以放置的棋子数量最大值为人口上限, 与商店等级相关;
		V-敌人根据当前回合数 * 200为生命值总和上限随机生成;
		V-购买完成按下游戏开始按钮到一方全部死亡为一个game, 双方全部单位行动完成为一个round, 单位自己的移动阶段+行动阶段为一个turn;
		V-从敌我双方随机一方开始(或者特定优先规则),双方依次移动+行动一个棋子, 如果一方完成所有棋子turn, 则行动完另一方所有剩下的棋子(或者另一方剩下的棋子都不能行动), 所有一方棋子的行动顺序可以从按钮区选择;
		(Shopping
		Game1: 
			Round1:
				Player1 Chess1 Turn: Move + Action;
				Player2 Chess1 Turn: Move + Action;
				Player1 Chess2 Turn: Move + Action;
				Player2 Chess2 Turn: Move + Action;
				Player1 Chess3 Turn: Move + Action;
				Player1 Chess4 Turn: Move + Action;
			Round2:
				Player1 Chess1 Turn: Move + Action;
				Player2 Chess1 Turn: Move + Action;
				Player1 Chess2 Turn: Move + Action;
				Player2 Chess2 Turn: Move + Action;
				Player1 Chess3 Turn: Move + Action;
				Player1 Chess4 Turn: Move + Action;
		Shopping
		Game2: 
			Round1:
				Player1 Chess1 Turn: Move + Action;
				Player2 Chess1 Turn: Move + Action;
				Player1 Chess2 Turn: Move + Action;
				Player2 Chess2 Turn: Move + Action;
				Player1 Chess3 Turn: Move + Action;
				Player1 Chess4 Turn: Move + Action;
			Round2:
				Player1 Chess1 Turn: Move + Action;
				Player2 Chess1 Turn: Move + Action;
				Player1 Chess2 Turn: Move + Action;
				Player2 Chess2 Turn: Move + Action;
				Player1 Chess3 Turn: Move + Action;
				Player1 Chess4 Turn: Move + Action;)
		V-棋子开始turn以后, 首先按照自己的目标优先方式(最近/最远/HP最高/HP最低)选择目标, 选择以后向着目标移动自身spd格子数量, 如果目标进入射程或者移动力消耗完则停止移动, 没有目标则跳过自身turn, 棋子可以进行斜向移动, 但是不能从两个棋子中间斜向穿过;
		V-棋子行动阶段如果目标在攻击范围内 && 与目标距离大于远程攻击阈值 && 有远程攻击动画则对目标进行远程攻击, 如果目标在攻击范围内 && 与目标距离小于远程攻击阈值 && 有近战攻击动画则对目标进行近战攻击, 都没有则结束turn;
		X-攻击目标之后可能会有的攻击特效接口(debuff...);
		V-如果目标没有闪避成功则对目标造成伤害, 伤害受自身buff/debuff/是否暴击/对手护甲等影响, 最终伤害值会累计到棋子自身的MP上;
		X-如果棋子MP已满且有法术动画/法术效果, 则释放法术一次, MP清零, 并放弃行动阶段;
		V-buff/debuff中的无敌/眩晕/沉默等效果会影响棋子是否可以进行移动/行动阶段等, 还包含攻击力/攻击次数/速度/护甲/闪避/暴击等修正 以及持续回复或者受伤等效果;
		V-玩家赢下X场或者输掉Y场 game则游戏结束;
		X-每个阵营上场棋子数量达到特定值后会触发阵营羁绊, 增加基础属性或者特定效果;
		V-每个game结束根据上个game的成功或者失败和上回合未使用金币数获得特定数量金币; 
		X-暴击/闪避/法术等粒子特效;
		V-debug模式下通过line连接棋子与目标;
		X-战斗中召唤其他棋子的逻辑;
		X-每次战斗更换棋盘样式;
		X-长按棋子显示棋子数据;
		X-战斗音乐 & 音效;
		V-战斗日志记录;
		X-buff/debuff图标
	V-等待区域
		V-等待区域的棋子不会进行移动行动阶段, 也不计入羁绊;
	V-商店区域
		X-商店每次game结束如果没有锁住会自动刷新;
		V-商店刷新的棋子数量以及稀有度与商店等级相关;
		V-商店升级需要花费特定数量金币;
		X-购买棋子时的羁绊提醒;
		X-棋子购买和出售的特效接口;
		X-除了棋子以外的物品或者村民效果;
		X-当前商店等级以及刷新棋子稀有度概率等显示;
	X-数据统计区域
		X-记录所有棋子在一次game中的造成伤害/收到伤害/造成治疗/收到治疗的总额, 并且按照从大到小的顺序显示双方加起来的前十名(或者只统计玩家的?);
		X-当前羁绊以及效果显示;
		X-当前胜场/负场数显示(小动物自走棋用的是奖杯和心);
	V-按钮
		V-商店刷新按钮
		V-商店锁住按钮
		V-商店升级按钮

		V-战斗开始按钮
		V-游戏重开按钮

		V-优先高HP行动按钮
		V-优先低HP行动按钮
		V-优先靠近中心行动按钮
		V-优先远离中心行动按钮

		X-暂停按钮?(用于检视电脑棋子属性)

X-游戏结束场景
	X-失败/胜利动画
	X-游戏重开按钮
	X-数据统计界面

X-选项场景
	X-选择游戏中出现的种族(在游戏过程中解锁?)
	X-难度
	X-音量?
	X-游戏速度
	...

X-图鉴场景
	X-将游戏中购买过的棋子在图鉴中显示, 其他棋子为灰色

X-统计场景
	X-统计游戏时间/胜利场数/购买棋子数量等信息
	X-重置按钮

