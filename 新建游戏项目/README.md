# 墨弈 · 水墨象棋

使用 Godot 4.7 打开本目录的 `project.godot`，按 F6 运行主场景或 F5 运行项目。玩家默认黑棋在下、先手，电脑执红。点击己方棋子，再点击圆点或红环行动。无合法行动的一方判负，包括困毙。

## 调整开局

在 Godot 文件系统中双击 `config/default_setup.tres`，在检视器展开 `pieces` 列表：

- 新增或删除 `PieceSetup` 条目来调整棋子数量。新增条目需选择“新建 PieceSetup”。
- `side`：BLACK 黑方、RED 红方；`kind`：KING 将帅、ADVISOR 士仕、ELEPHANT 象相、HORSE 马、ROOK 车、CANNON 炮、PAWN 兵卒。
- `position` 为交叉点坐标，左上 `(0, 0)`、右下 `(8, 9)`。黑方底线为 y=9，黑卒向 y 递减方向前进；红方相反。
- `health` 配置初始及最大血量；`player_side` 配置玩家阵营；`first_side` 配置先手方。

保存资源后点击游戏“重新开局”会从磁盘重新加载开局资源。也可新建 GameSetup 资源，在 `scenes/main.tscn` 根节点的 `setup` 字段指定。新建资源需保存为 `.tres`，各开局布局可以独立复用。

坐标不可重叠或越界，血量须大于零，双方各需一个九宫内的将帅，开局不可将帅照面。其他棋子允许自由布置，但行动时仍遵守棋种限制。配置错误会在游戏右侧显示并阻止开局。

## 血量规则

攻击扣一血且消耗回合。目标存活时双方位置不变，目标死亡时攻击者占据目标位置。所有棋子包括将帅都可配置多血量。将帅只有面对下一次攻击就会死亡的威胁时才算将军，非致命攻击后按剩余血量重新判定；将帅照面始终禁止。默认全员一血时与常规象棋吃子和将军行为一致，默认黑方先手是本作的设置。

初版不裁定长将、长捉或重复局面和棋。电脑使用两层搜索；重开后旧搜索结果会被丢弃。棋盘、装饰和棋子均为代码绘制，可直接调色和缩放，无外部图片依赖。字体优先使用系统楷体，回退到可用的中文系统字体。

## 验证

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_rules.gd
godot --path . --script res://tests/test_scene.gd
```

最后一项检查场景交互、AI、重开与缩放，并生成 `artifacts/board_preview.png` 和 `artifacts/board_small.png`。
