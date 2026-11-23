# lemon Roblox 通用项目架构与开发规范

更新日期：2026-11-23。适用于采用本架构的 Roblox 项目的业务代码、配置、UI、测试及临时调试脚本。

本文是适用于采用本架构的 Roblox 项目的唯一完整开发规范，供开发者及 AI 协作者执行。AGENTS.md 仅作为 AI 工作入口，指引读取本文，不重复保存具体规则。用户明确的新决定优先于旧规范；发生冲突应说明并更新本文，不能把旧代码当成例外依据。

## 一、项目概况与阅读入口

本规范面向可复用的 Roblox 项目基础架构，适用于不同题材和玩法，不以 ColorGuess 或任何具体业务系统为前提。核心约束是服务端分层、业务协议解耦、客户端数据与表现分离、严格类型和服务端权威校验。

技术体系为 Roblox、Luau、Rojo、ByteNetMax fork 和 ProfileStore。当前仓库工具锁定 Rojo 7.7.0、luau-lsp 1.69.0，具体版本以 aftman.toml 为准；其他项目采用此规范时应核对自己的工具版本和映射。

开发前必须阅读本文；AGENTS.md 只提供阅读指引，不能代替本文。具体行为再核对代码、网络定义、DataTypes、配置源和启动清单。

本文区分两类内容：禁止事项、分层、类型、接口与开发流程是通用规范；目录映射、入口文件、已注册系统和已知实现差距是当前仓库快照。后者用于定位，不要求每个使用本规范的游戏都实现相同玩法或系统。不同项目可以增减业务系统，但不能因此放宽架构边界。

## 二、禁止事项

1. 禁止 `_G`、全局 `shared`、`getfenv`、`setfenv`，临时脚本与测试也不例外。共享状态通过显式依赖或协议传递。
2. 禁止跨业务系统 require 对方的 Manager、Service、Controller、ServerClass、ClientClass、BaseClass、Registry、领域对象等内部实现；继承也不能绕过系统边界。
3. 禁止跨系统访问通用能力内部实现；只允许已批准的公开入口。目录叫 shared、模块叫 Manager 都不构成访问许可。
4. 禁止把玩家业务参数声明成 `Instance` / `any`，或使用 userID 代替在线玩家业务接口中的 `Player`。离线查询、身份持久化、日志及平台 API 等确需 ID 的边界除外。
5. 禁止把“是 Instance”当成“是 Player”；运行时必须确认 Player 类别。
6. 禁止 Profile 映射表使用 number / Player / Instance key；持久化映射必须 string key。
7. 禁止在业务模块分散定义 `export type`，禁止用无约束 any 绕开业务类型。
8. 禁止 ByteNet packet / query 使用冒号调用，统一点语法。
9. 禁止 UI 面板省略独立 DataController；禁止面板 Controller 直接进行业务网络请求或同步监听；禁止 Window 编写业务逻辑。
10. 禁止把 GoodsRouteConfig、完整 CDK 码表、服务端保底配置放入客户端可见目录，或通过快照原样公开。
11. 禁止在监听未就绪时发跨系统请求或通知；禁止以启动清单位置推断异步初始化完成顺序。
12. 禁止延迟到玩家离开时才回写业务变更到 profile.Data。
13. 禁止把现有不合规实现、旧示例或暂未修复问题当成新代码的许可。
14. 除明确的通用错误码外，禁止跨系统复用业务错误码，或用笼统通用错误码代替可明确区分的系统业务失败。

## 三、当前新项目状态与入口

2026-11-23 按用户要求将复制自 1wizard 的工程清理为新项目。当前项目名为 StealALittlePony，默认 Rojo 端口 34873，与源工程 34872 分开。

### 3.1 当前映射

| 本地路径 | Roblox 路径 | 职责 |
|---|---|---|
| src/server | ServerScriptService.Scripts | ServerMain 启动区域刷蛋 |
| src/client | StarterPlayer.StarterPlayerScripts.Scripts | 空客户端入口 Main.client.lua |
| src/shared | ReplicatedStorage.Scripts | 通用库、工具、空配置目录与空协议聚合器 |
| src/server-storage | ServerStorage.Scripts | 区域刷蛋模块与私有表、未启用的 ProfileStore 库、空内部协议目录 |
| src/replicated-first | ReplicatedFirst.Scripts | 空目录 |
| src/gui | StarterGui.Scripts | 空目录 |
| src/workspace | Workspace.Scripts | 空目录 |

空目录通过 init.meta.json 保持 Folder 类型并纳入版本管理。configSource 包含区域与蛋池两张 CSV。build 只存工具及本项目生成的验证产物，不同步到游戏。

### 3.2 启用状态

- 服务端启动 EggSpawnManager，从每区的 EggNests 模板生成与补充野外蛋。场景蛋巢通过 assets/egg-spawns 映射，以便本地构建复现。客户端仍是空入口，StarterGui 保留小马项目的静态 UI。
- src/shared/network/init.lua 返回空表；tools/config-puller/sources.json 仅注册 EggSpawnRegions 和 EggSpawnPool。旧 CSV、Excel、JSON 和 Luau 业务配置均已移出当前项目，不通过空记录或禁用标记继续保留。
- 保留 ByteNetMax、ProfileStore 源码供后续显式接入；ProfileStore 位于 src/server-storage/Packages/ProfileStore.luau。保留 Validate、ConfigHelper，以及 DataTypes / ErrorCodes。
- 已移除旧自定义 PlayerModule、输入绑定、UI、模型、动画与 VFX 映射。运行时使用 Roblox 默认角色、相机和 CoreGui 行为。
- 旧 GameLauncher / ClientLauncher 及业务清单不保留在当前工程，避免 require 已移除系统、等待旧 dataLoaded 或访问旧存档。新增系统时按实际需求建立生命周期调度，不添加旧项目恢复开关。
- 当时只整理本地源码，不修改正在打开的 Studio place。旧 place 中手工保存的场景或 GUI 不会因清理本地文件自动消失；新项目应使用自己的 place 与场景。

### 3.3 归档与后续开发

旧系统源码、业务配置、资源、插件、旧测试、产物、项目映射和原规范保存在项目外的 `E:/project/StealALittlePony-legacy-20261123-112151`。源项目 `E:/project/1wizard` 未修改。归档不进入 Rojo 映射或新项目仓库；复用时只按需求取回模块，并重新接入配置、协议、类型及生命周期。

以下章节保留通用开发约束。UserDataSystem、ResourceService、UIManager、InputSystem、SoundManager、clientModules、ui/config 以及生命周期启动器等名称表示未来按需接入的架构约定，不表示当前文件或系统已经存在。新增业务仍须遵守分层、跨系统协议、独立 UI 数据层和服务端权威校验；不要依据旧项目快照重新自动启用系统。

## 四、系统分层与每层职责

### 4.1 服务端：按职责选择层级

服务端不固定为三层，也不强制存在 Service。根据系统是否管理多个对象、是否需要服务端实体行为、是否存在可复用基类，选择清晰且必要的层级。

以下都是允许的组织方式，箭头含义需区分：

```text
组合根：ServerMain / GameLauncher → XxxManager

对象型系统：
XxxManager → XxxController → XxxServerClass
                                  └─ 继承 XxxBaseClass（按需，统一 rawget 模板）

服务型系统：
XxxManager → XxxService → 领域对象 / 算法 / Profile 数据（按需）

简单系统：
XxxManager → XxxController
```

Manager → Controller / Service 表示生命周期与编排调用；Controller → ServerClass 表示创建、管理或调用对象；采用 ServerClass / ClientClass → BaseClass 结构时，使用第 4.4 节统一继承模板，不是必须依次执行的启动链。对象可以组合其他能力，但不能用另一套构造方式替代这套继承契约。不能为了满足图示制造空层，也不能把所有职责堆到一个模块。

| 角色 | 负责 | 边界 |
|---|---|---|
| Manager | 面向组合根提供 initialize / onPlayerAdded / onPlayerRemoving / shutdown；组装本系统并转发生命周期 | 保持薄入口，不堆业务算法、网络 handler 或存档规则 |
| 服务端 Controller | 协调本系统对象，管理对象创建、索引、销毁及业务流程；按明确分工接入网络与玩家生命周期 | 不承担 UI 面板职责，不直接依赖其他业务系统内部实现，不替对象保存重复的权威状态 |
| Service（可选） | 请求处理、业务流程、权限校验、资源与存档编排、同步及幂等；适合服务型业务 | 不是所有系统必需；与 Controller 同时存在时必须明确分工，不能重复处理同一流程 |
| ServerClass（可选） | 单个服务端实体的状态、行为与对象生命周期，例如角色、生物、房间或交互对象 | 可持有按契约传入的 Player / 场景对象，但不管理全系统入口、不承担其他系统业务；不能误当作纯算法模块 |
| BaseClass（可选） | 抽取同类对象的共同属性、方法、生命周期契约与可覆盖行为 | 不反向 require 具体 ServerClass、Controller 或 Manager；不硬编码某个子类业务，不成为杂项工具集合 |
| 纯领域对象 / 算法（可选） | 规则计算、背包计算、抽取算法等可独立验证的逻辑 | 接收普通数据，不依赖网络、Player 生命周期、场景查找或存档加载 |

每个系统必须明确以下归属，而不是按文件后缀猜测职责：

- 谁注册网络和本地协议监听，谁完成权限与业务校验。
- 谁创建、查找、持有和销毁对象，谁拥有权威状态。
- 谁通过存档入口回写数据，谁负责同步与通知。
- 谁清理玩家退出、对象销毁和 shutdown 时的连接、计时器及缓存。

这些职责可以由 Controller 或 Service 编排，也可通过明确的对象契约委托给 ServerClass；不能多处重复监听、重复发奖、重复回写或互相等待。服务端所有收参函数的 Validate.args、Player 校验、DataTypes 和跨系统协议要求对每种角色均适用。

依赖由上层指向下层。BaseClass 不反向 require 子类或管理层；子类扩展通过显式方法覆盖或组合实现。继承只用于确有共同契约的对象，不能仅为复用几行代码引入基类。同系统内部继承允许；跨业务系统不能直接继承对方的内部类。共享基础类须具有明确批准的公共契约，不能仅以 BaseClass 命名自动获得白名单资格。

以下是可选文件集合，不要求全部创建：

```text
src/server-storage/Xxx/
  XxxManager.lua
  XxxController.lua    # 对象与流程编排
  XxxService.lua       # 服务型业务按需采用
  XxxServerClass.lua   # 服务端实体
  XxxBaseClass.lua     # 同类对象公共契约
  XxxResolver.lua      # 纯算法
src/server-storage/network/XxxInternal.lua
src/shared/network/XxxNetwork.lua  # 需要跨端时
```

ServerClass 及服务端专用基类放服务端目录。需要跨端复用的 BaseClass 只能包含允许公开的基础逻辑，不能把私有配置或服务端权限实现随基类放到 shared。

### 4.2 客户端业务层

Bootstrap / Manager 负责组合和生命周期；DataController 负责状态、网络请求、同步、版本处理与数据事件；表现模块执行动画、声音或场景展示。

业务状态不由 Window 或通用 UI / Sound 框架管理。业务系统可以调用通用能力，通用能力不能反向依赖具体业务。

需要对象化表现时可使用 ClientClass，由客户端本系统 Controller 管理。ClientClass 与 ServerClass 分别继承同系统 BaseClass，互不继承、互不 require；客户端对象不拥有服务器业务权威。三者统一采用第 4.4 节模板。

### 4.3 UI：强制独立三层

每个面板必须有独立 DataController，单面板独占状态也不例外。可复用已有业务数据服务，面板数据层负责适配，不重复保存同一份权威状态。

| 层 | 负责 | 禁止 |
|---|---|---|
| XxxDataController | 业务状态、网络请求与同步、数据计算、快照与数据事件 | 操作 GUI、依赖 UIManager、调用面板 Controller |
| XxxController | PanelBaseClass 生命周期、转发动作、订阅数据层、组织 render、调用 UIManager / SoundManager | 直连业务网络、保存业务真相、计算奖励和权限 |
| XxxWindow | 缓存 UI 引用、render、一次性 bindActions、报告操作 | require 数据层、网络请求、业务状态、发奖或导航 |

Controller 可保存订阅、动画句柄等生命周期状态；业务数据归 DataController。同系统数据层公开调用允许，跨业务系统必须使用本地协议。

框架先 `WindowClass.new(gui)`，再 `ControllerClass.newObject(ControllerClass, key, window)`。Controller 接收 window，不在 onCreate 重复构造。

onCreate 一次性绑按钮；onEnabled 订阅显示期数据并刷新；onDisable 退订显示期监听。需要在隐藏状态自动打开面板的事件，应建立常驻订阅并在销毁时清理，不能只在 onEnabled 监听。

面板注册在 src/client/ui/config.lua，数据层通过 clientModules 或本系统 Bootstrap 初始化。仅创建文件不算完成接线。

业务按钮保留正常外观与点击反馈；条件不足、已领取、请求处理中仍通过业务校验反馈，保留请求互斥与幂等，不重复扣费发奖。倒计时、已领取标记及设置值可以继续展示，不以改变这些业务状态为由绕过服务端验证。

### 4.4 BaseClass / ServerClass / ClientClass 统一继承模板

采用表式 `__index` 和 `rawget` 的同一套继承骨架，不混用另一套类库或函数式 `__index`。BaseClass 定义 `new`（造类）与 `_alloc`（分配实例）；ServerClass / ClientClass 继承 `new`，各自实现 `newObject`（造实例）。不能把某个子类的 `new` 改成实例构造器。

统一的是继承和构造机制，不是业务参数签名。`newObject` 的参数数量、名称、类型及顺序由具体类决定，不要求 objectID、player，也不要求 ServerClass 与 ClientClass 接收相同参数。可以无业务参数、使用多个具名参数，或使用 DataTypes 中明确声明的参数结构；不能为了通用性改成无约束的 `...: any`。`_alloc` 也只接收该基类真正需要的公共参数。

以下三个类采用无业务参数的最小骨架，便于直接复用；这不强制实际构造器无参。落地时为实际参数补充类型、Validate.args 和字段初始化；只有涉及玩家时才增加 Player 参数及类别校验。

```text
XxxBaseClass
  ├─ XxxServerClass   # 服务器权威实体
  └─ XxxClientClass   # 客户端对象与表现

实例 → 本次构造的派生类 → 端侧类 → BaseClass
```

`rawget(class, "__index")` 只检查类表本身。不能写 `if class.__index == nil`，因为它可能读到父类继承来的值，导致本类没有自己的 `__index`，后续实例无法正确查到本类覆盖方法。每个类必须拥有指向自身的表式 `__index`。

以下 Xxx 是同一系统的占位名。BaseClass 共享时放 `src/shared/xxx/XxxBaseClass.lua`；ServerClass 放 `src/server-storage/Xxx/XxxServerClass.lua`；ClientClass 示例放 `src/client/xxx/XxxClientClass.lua`。跨容器 require 使用完整路径。共享的是定义，不是实例或内存状态，跨端同步仍走网络。

#### 4.4.1 DataTypes：先定义实例契约

下列类型加入现有 `src/shared/tools/DataTypes.lua`，不要重复创建模块，也不要在三个类文件内 export type。这里只定义生命周期骨架；业务字段及需要的构造参数结构由具体类补充，不预设 ID 或玩家。

```lua
-- 添加到现有 DataTypes.lua 的类型区
export type XxxBaseObject = {
    isDestroyed: boolean,
    connections: { RBXScriptConnection },
    destroy: (self: XxxBaseObject) -> (),
}

export type XxxServerObject = XxxBaseObject -- 按需交叉扩展服务器字段
export type XxxClientObject = XxxBaseObject -- 按需交叉扩展客户端字段
```

构造元表时的类表 `self` / `class` 可局部使用 any，以隔离自引用元表的推断边界；`_alloc` → 具体实例的断言也仅限构造位置。这个例外只适用于继承机制，不允许业务参数、Player、状态、网络载荷使用 any。公开实例类型仍由 DataTypes 完整定义，实例方法的 self 必须标注具体类型。

#### 4.4.2 BaseClass 模板

```lua
--!strict
-- src/shared/xxx/XxxBaseClass.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Scripts.tools.DataTypes)
local Validate = require(ReplicatedStorage.Scripts.tools.Validate)
type BaseObject = DataTypes.XxxBaseObject

local XxxBaseClass = {}
XxxBaseClass.__index = XxxBaseClass

-- 造类；self 是父类，classTable 是可选的新类表。
function XxxBaseClass.new(self: any, classTable: any?): any
    if not Validate.args("XxxBaseClass.new", {
        { name = "self", value = self, expected = "table" },
        { name = "classTable", value = classTable, expected = "table", optional = true },
    }) then
        error("[XxxBaseClass.new] invalid args")
    end
    local class: any = classTable or {}
    if class == self then
        error("[XxxBaseClass.new] class must differ from parent")
    end
    if rawget(class, "__index") == nil then
        class.__index = class
    end
    if rawget(class, "__index") ~= class then
        error("[XxxBaseClass.new] __index must reference the class itself")
    end
    return setmetatable(class, self)
end

-- 只分配公共字段；不调用可覆盖方法，不注册网络或对象索引。
function XxxBaseClass._alloc(self: any): BaseObject
    if not Validate.args("XxxBaseClass._alloc", {
        { name = "self", value = self, expected = "table" },
    }) then
        error("[XxxBaseClass._alloc] invalid args")
    end
    if rawget(self, "__index") ~= self then
        error("[XxxBaseClass._alloc] expected a class table")
    end
    return setmetatable({
        isDestroyed = false,
        connections = {}, -- 每次分配新表，不放在类表上共享
    }, self) :: any
end

function XxxBaseClass.destroy(self: BaseObject): ()
    if not Validate.args("XxxBaseClass.destroy", {
        { name = "self", value = self, expected = "table" },
    }) then
        return
    end
    if self.isDestroyed then
        return
    end
    self.isDestroyed = true
    for _, connection in self.connections do
        connection:Disconnect()
    end
    table.clear(self.connections)
end

return XxxBaseClass
```

`new` 只接受新建、尚未连接继承链的 classTable；不得把已使用的类重新挂到别的父类或引入继承环。BaseClass 的构造过程不调用子类可覆盖方法，避免子类字段尚未初始化时提前执行。

#### 4.4.3 ServerClass 模板

```lua
--!strict
-- src/server-storage/Xxx/XxxServerClass.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Scripts.tools.DataTypes)
local Validate = require(ReplicatedStorage.Scripts.tools.Validate)
local XxxBaseClass = require(ReplicatedStorage.Scripts.xxx.XxxBaseClass)
type ServerObject = DataTypes.XxxServerObject

local XxxServerClass = XxxBaseClass:new()

function XxxServerClass.newObject(self: any): ServerObject
    if not Validate.args("XxxServerClass.newObject", {
        { name = "self", value = self, expected = "table" },
    }) then
        error("[XxxServerClass.newObject] invalid args")
    end
    local obj = (XxxBaseClass._alloc(self) :: any) :: ServerObject
    -- 在此初始化服务器专属实例字段；不得放到 XxxServerClass 类表上。
    return obj
end

function XxxServerClass.destroy(self: ServerObject): ()
    if not Validate.args("XxxServerClass.destroy", {
        { name = "self", value = self, expected = "table" },
    }) then
        return
    end
    if self.isDestroyed then
        return
    end
    -- 同步清理本层拥有的资源；共享连接由基类清理。
    XxxBaseClass.destroy(self)
end

return XxxServerClass
```

#### 4.4.4 ClientClass 模板

```lua
--!strict
-- src/client/xxx/XxxClientClass.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Scripts.tools.DataTypes)
local Validate = require(ReplicatedStorage.Scripts.tools.Validate)
local XxxBaseClass = require(ReplicatedStorage.Scripts.xxx.XxxBaseClass)
type ClientObject = DataTypes.XxxClientObject

local XxxClientClass = XxxBaseClass:new()

function XxxClientClass.newObject(self: any): ClientObject
    if not Validate.args("XxxClientClass.newObject", {
        { name = "self", value = self, expected = "table" },
    }) then
        error("[XxxClientClass.newObject] invalid args")
    end
    local obj = (XxxBaseClass._alloc(self) :: any) :: ClientObject
    -- 在此初始化客户端专属实例字段；不得放到 XxxClientClass 类表上。
    return obj
end

function XxxClientClass.destroy(self: ClientObject): ()
    if not Validate.args("XxxClientClass.destroy", {
        { name = "self", value = self, expected = "table" },
    }) then
        return
    end
    if self.isDestroyed then
        return
    end
    -- 仅清理本对象拥有的客户端资源，不销毁外部传入的 Player / Character。
    XxxBaseClass.destroy(self)
end

return XxxClientClass
```

#### 4.4.5 构造、覆盖与清理约定

- 创建端侧类：`local XxxServerClass = XxxBaseClass:new()`，ClientClass 同样写法。直接继承的两类共享机制，不互相依赖。
- 创建实例：最小骨架为 `XxxServerClass:newObject()` / `XxxClientClass:newObject()`；实际可以是 `RoomServerClass:newObject(roomConfig)`、`EffectClientClass:newObject(model, duration)` 或其他明确类型的签名。示例参数都不是统一要求。普通类方法可以使用冒号；ByteNet 的点语法规则不变。
- 继续派生：`local SpecialServerClass = XxxServerClass:new()`。继承的 newObject 必须使用传入 self 分配实例，不能写死 `setmetatable(obj, XxxServerClass)`，否则会丢掉更深一层的覆盖方法。
- 覆盖构造器时显式调用直接父类 `ParentClass.newObject(self, ...)`，只传父类契约要求的参数，再初始化本层字段；这里的省略号表示按契约填写实参，不要求实现无类型可变参数。不能调用 `self:newObject(...)` 造成递归。若通过工厂统一构造多个子类，由该工厂定义兼容的参数契约，不扩展成所有系统的固定签名。
- 覆盖方法调用父实现用 `ParentClass.method(self, ...)`，不要再次调用 `self:method(...)`。BaseClass 不反向 require 子类，也不复制一份父类方法表到子类。
- BaseClass 只初始化公共字段，端侧类只初始化端侧字段。所有可变表、连接、计时器及资源句柄按实例独立持有；常量与方法可以放类表。
- destroy 同步、可重复调用，按“本层清理 → 直接父类清理”执行；由基类最终设置销毁标记。上层不能提前置标记导致父类跳过清理；清理过程中不 yield、不触发再次进入 destroy 的业务回调。
- 本模板仅有连接清理。增加计时器、模型、动画等资源时必须声明所有权并补清理；异步回调检查销毁状态，Controller 从索引移除实例。外部传入的 Player、Character 和共享资源不得随对象误删。
- 构造器契约返回非可选对象，参数错误使用 error；业务边界在调用前验证，必要时捕获并转换 ErrorResult。不得返回 nil 伪装构造成功。业务公开方法仍遵守统一错误返回。
- 验证至少覆盖：继承方法与子类覆盖、二次派生后的实例元表、同类两个实例的可变状态隔离、两端派生类互不污染、重复销毁，以及实际构造参数的错误输入拒绝；涉及 Player 时验证类别拒绝。

这些模板是新增类的统一骨架，不表示既有类已全部迁移。具体对象是否需要 ServerClass / ClientClass 由职责决定；一旦采用该继承模式，就必须遵守同一套 new / _alloc / newObject 契约。

## 五、require 白名单与接口边界

### 5.1 允许直接 require

| 目标 | 范围 |
|---|---|
| 同系统内部模块 | 按职责选择 Manager → Controller / Service、Controller → ServerClass / ClientClass、端侧类 → BaseClass、业务编排 → 领域模块；UI 同系统组合与继承 |
| src/shared/network | 双端协议、客户端本地协议与事件契约 |
| src/server-storage/network | 服务端本地协议，仅服务端访问 |
| src/shared/tools | DataTypes / Enums / ErrorCodes / Validate / ConfigHelper / ModelHelper / VfxHelper 等工具 |
| src/shared/config | 批准公开的配置数据，不含 ConfigHelper 实现或服务器专用表 |
| UserData/UserDataSystem | 存档公共入口，业务系统取得相应玩家数据 |
| Resource/ResourceService | 资源检查、消耗、发放统一入口 |
| shared/ui/UIManager | 已初始化的 UI 导航公开方法 |
| shared/input/InputSystem | 客户端 IAS 公共入口。通过 `getAction(contextName, actionName)` 获取原生 InputAction，通过 `setContextEnabled(contextName, enabled)` 切换本机上下文。 |
| shared/sound/SoundManager | 已初始化的播放、音量、静音公开方法 |
| 组合根与启动器 | ServerMain / GameLauncher / clientModules / 本系统 Bootstrap 按职责组装系统，不是业务层绕过边界的后门 |

ByteNetMax 等基础依赖按职责由网络层、基础设施及组合根加载，不扩大业务系统互相 require 的权限。新增通用能力先明确公开契约，不能自称工具绕过白名单。

未来接入客户端 IAS 时，配置约定放在 `ReplicatedStorage.Scripts.input.Contexts`。InputContext 平级放置，动作是上下文的直接子节点，绑定挂在动作下面；同级配置使用唯一名称。Gameplay 默认开启，Menu 默认关闭，开启后优先处理自身绑定的输入。调用方直接订阅原生 `Pressed`、`Released` 或 `StateChanged`，用 `GetState()` 读取当前值，并在自身生命周期结束时断开连接。上下文开关由管理相应模式的模块负责。自定义输入可通过 Scriptable 类型的 InputBinding 调用 `binding:Fire(value)`。当前没有 IAS 项目预设；未来新增的 Studio 输入配置若需随源码分发，应补充对应 Rojo 配置。

### 5.2 必须通过协议的场景

| 场景 | 方式 |
|---|---|
| 查询或修改其他业务系统 | 本地 query.invokeToLocal |
| 通知其他业务系统变化 | 本地 packet.sendToLocal |
| 货币、道具等资源操作 | ResourceService，内部再调用各系统协议 |
| 客户端请求服务端业务 | 双端 query.invoke，服务端校验 |
| 服务端同步客户端 | 双端 packet.sendTo / sendToAll 等 |
| UI 面板请求业务数据或操作 | 自己的 DataController，跨业务由本地协议解耦 |

Purchase 不得直接 require InventoryService；PetDraw 不得直接 require PetService。设置系统可以调用 SoundManager 应用偏好，但不能访问 SoundController / BusGraph / Registry。

跨服务容器引用必须完整路径：

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataTypes = require(ReplicatedStorage.Scripts.tools.DataTypes)
local ResourceService = require(ServerStorage.Scripts.Resource.ResourceService)
local XxxInternal = require(ServerStorage.Scripts.network.XxxInternal)
```

同系统可使用 script.Parent 相对路径，禁止通过多层 Parent 跨 Roblox 服务寻找其他容器。

### 5.3 接口职责单一与事件载荷精简

接口和事件按明确的业务用途设计，只传递完成该用途所必需的信息。本规则同时适用于服务器同端、客户端同端和双端协议，也适用于业务公开方法。

- 查询接口保持职责单一，按实际调用需求返回最小数据。调用方只需要重生次数时，提供 `getRebirthCount`，不要让它获取包含 trainingValue、等级、倍率、离线上限和预览的整份状态后只取一个字段。不为尚不存在的需求预塞字段。
- 操作接口一次完成一个明确的业务动作，请求只携带执行与校验所需参数，响应只返回调用方确实需要的结果；无需结果数据时只返回 code，不顺带返回整个玩家状态。继续遵守 ErrorResult 契约，精简不代表省略必要的错误码。
- 事件表达一个已经发生的业务事实，载荷只包含识别对象及消费该变化所必需的字段。例如同端重生完成通知可使用 `{ player, count }`；没有具体消费需求时，不附带完整存档、配置、旧值、收益预览或请求参数。订阅者需要其他独立信息时，通过对应查询接口获取。
- 可由已有公开配置与标识确定的信息，不在各接口和事件中重复传输；但需要表达事件发生时的值时，应携带必要快照，不能以事后查询当前值替代历史事实。幂等、顺序、权限或一致性确需的凭证和版本字段可以保留，必须有明确用途。
- 职责单一不等于机械地拆成每字段一个请求。同一业务用途确实需要一起读取、且要求一致性的少量字段可以组合返回；不得为了少发一次请求，合并互不相关的查询或设计无边界的通用状态接口。也不为查询不同字段而引入任意字段列表或存档路径访问器。
- 定义或调整协议时核对实际调用方和订阅方：每个字段都应有必要的业务用途，删除无消费者的冗余信息，并同步维护 DataTypes、Schema 和调用方。

## 六、DataTypes、命名与返回值

### 6.1 类型是必需项

新增或修改业务接口时必须定义请求、返回载荷、状态及存档结构。所有 `export type` 集中于 src/shared/tools/DataTypes.lua；使用方通过 `type Xxx = DataTypes.Xxx` 引入，不在模块另行导出或重复定义同一契约。

仅文件内部临时类型可以使用非导出 type；公共业务契约必须进入 DataTypes。参数和返回值必须有类型标注，不能用 any 代替设计。第三方边界确需 any / unknown 时局部收窄和校验，不向业务层扩散。第 4.4 节继承机制的类表和实例构造断言允许局部 any；不得扩散到实例业务方法、Player 或业务数据。

```lua
-- 添加到 DataTypes.lua 的现有模块中
export type WidgetRequest = { itemID: string }
export type WidgetInternalRequest = { player: Player, itemID: string }
export type WidgetState = { counts: { [string]: number } }
export type WidgetCountData = { count: number }
```

类型不能替代运行时校验，也不能替代 ByteNet schema。

### 6.2 命名与文件

| 对象 | 规则 | 示例 |
|---|---|---|
| 变量、函数、方法、网络字段及端点 | camelCase | itemCount / getSnapshot / purchaseGoods |
| 模块表、类型、命名空间 | PascalCase | PetService / PetSnapshot / PetInternal |
| 常量 | SCREAMING_SNAKE_CASE | MAX_STACK_SIZE |
| 枚举 key | PascalCase | ItemType.Weapon |
| 枚举值 | camelCase 字符串，或有明确顺序需求的数值 | "weapon" / 4 |
| ID / URL 等缩写 | 全大写或独立全小写 | itemID / userID / id，不用 itemId |

Roblox / 第三方 API 保留原名，如 player.UserId、profile:AddUserId。配置枚举填真实值，代码引用已定义 ID 优先使用 Enums 别名。

Lua / Luau 文件第一行必须 `--!strict` 或 `--!nonstrict`，新业务代码默认 strict，不为隐藏错误随意降级。

### 6.3 ErrorResult

业务结果统一为 `ErrorResult = { code: number, data: any? }`，通过 ErrorCodes.result 构造。成功只比较 code，不添加 success / message，客户端用 ErrorCodes.getMessage(code) 获取文案。

```lua
return ErrorCodes.result(ErrorCodes.Codes.SUCCESS, data)
return ErrorCodes.result(ErrorCodes.Codes.INVALID_PARAMETER)
```

载荷本身仍需业务类型。既有纯 getter、无失败计数、生命周期与框架 API 按其明确契约返回。已有网络单标量 code 可保留 uint16；不得在同一调用点混用裸 code 和 ErrorResult。

### 6.4 错误码归属与提示文案

除通用错误码外，每个系统的业务错误必须独立定义。该规则适用于服务端、客户端、双端查询和同端查询，不因调用方式而改变。

- 通用错误码仅表示与具体业务无关、语义一致的结果，例如 SUCCESS、INVALID_PARAMETER、OPERATION_TIMEOUT、INTERNAL_ERROR。已有错误码没有系统前缀，不代表它就是通用错误码；按业务含义判断归属。
- 每个系统使用独立的名称前缀和不重叠的数值号段，统一在 `src/shared/tools/ErrorCodes.lua` 的 `ErrorCodes.Codes` 中集中登记，不在各业务模块另建错误码表或写裸数字。新增号段前检查已有分配；通过当前 uint16 协议传输的错误码必须在 0..65535 范围内。已发布错误码不随意改值或改义，废弃编号不重新分配给其他含义。
- 系统业务失败应有明确含义，例如 Weapon 的未持有、未装备、已满星、武器受保护，以及 Attack 的攻击冷却、技能冷却、无有效目标、请求过快。命名可采用 `WEAPON_NOT_OWNED`、`WEAPON_MAX_STAR`、`ATTACK_COOLDOWN`、`ATTACK_SKILL_COOLDOWN`；这些是命名示例，不表示当前代码已经定义。
- 不得把武器业务错误写成 Inventory / Item 的业务错误，也不得把攻击冷却写成 `CANNOT_USE_ITEM`。请求冲突、版本过期、操作占用、频率限制等需要分别处理的系统状态，不得全部合并成 `DATA_LOCKED`；满星、保护限制等也不能全部以 `PERMISSION_DENIED` 掩盖具体原因。
- 调用其他系统收到失败时，按接口契约保留来源系统的错误码，或明确转换为本系统错误码；不得借用对方错误码表示本系统产生的另一种失败。
- 每个新增错误码必须同步维护 `ErrorCodes.Messages` 对应文案，客户端通过 `ErrorCodes.getMessage(code)` 获取。Messages 是文案映射，不会自动打印、弹窗或显示 UI；日志与界面展示由调用方负责。业务响应保持 `{ code, data }`，不重复携带 message，也不靠比较文案判断结果。
- 修改错误分支时，同步检查协议类型、调用方处理与相关测试，验证成功、可重试失败和不可重试失败的区分。配置加载或构造中的程序错误可以按原契约抛出；正常可预期的业务失败使用 ErrorResult。

## 七、Player 与参数校验

### 7.1 玩家必须为 Player

- 参数写 `player: Player`，结构字段写 `player: Player`，可选才写 Player?。
- 服务端在线玩家本地协议传 Player，不传 userID 让各系统反查。
- 客户端修改本人数据不提交可替换的 player；服务端使用跨端 listener 的第二个参数，即网络层提供的实际调用者。
- 查询他人公开展示数据可传 targetPlayer: Player，但校验目标并限制可读字段，不能借此修改他人数据。
- Player / Instance 不能写入持久化 profile，记录身份时用平台 ID 或字符串 key。

### 7.2 运行时校验

服务端所有收参函数，包括私有函数、生命周期函数、网络 handler 和已有类型标注的函数，都必须调用 Validate.args。schema、本地调用、上游已校验不能替代这一要求。

当前 Validate.expected 比较 typeof。Roblox 的 typeof(player) 是 "Instance"，所以工具基础检查仍写 expected="Instance"，但必须紧接着确认 IsA("Player")，不能因此接受任意 Instance。工具目前没有 expected="Player" / className 功能，不得假定它已经支持。

适配当前工具的完整示例（这里使用 Service 命名仅作示例；Controller、ServerClass、BaseClass 的服务端收参方法同样适用）：

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Scripts.tools.DataTypes)
local Validate = require(ReplicatedStorage.Scripts.tools.Validate)
local ErrorCodes = require(ReplicatedStorage.Scripts.tools.ErrorCodes)
type ErrorResult = DataTypes.ErrorResult
local WidgetService = {}

function WidgetService.checkRequest(player: Player, itemID: string): ErrorResult
    if not Validate.args("WidgetService.checkRequest", {
        { name = "player", value = player, expected = "Instance" },
        { name = "itemID", value = itemID, expected = "string", nonEmpty = true },
    }) then
        return ErrorCodes.result(ErrorCodes.Codes.INVALID_PARAMETER)
    end
    if not player:IsA("Player") then
        return ErrorCodes.result(ErrorCodes.Codes.INVALID_PARAMETER)
    end
    return ErrorCodes.result(ErrorCodes.Codes.SUCCESS)
end

return WidgetService
```

结构体先确认 table，再读取并校验字段与嵌套结构；只检查 table 不算完成。数值按业务约束 min / max / integer，当前 Validate 自动拒绝 NaN 和无穷大。

Player 类别正确之外，还须按操作检查当前服务器成员身份、数据就绪、归属、价格、条件及次数等。无 ErrorResult 的生命周期 / 私有函数失败后按契约安全退出。

## 八、服务器 network 与公共 network

### 8.1 三种协议

| 类型 | 位置 | 定义方式 | 用途 |
|---|---|---|---|
| 双端协议 | src/shared/network/XxxNetwork.lua | defineNamespace | 客户端和服务端均加载，跨端业务 |
| 服务端内部协议 | src/server-storage/network/XxxInternal.lua | defineLocalNamespace | 仅服务器业务间调用 |
| 客户端内部协议 | src/shared/network/XxxClientInternal.lua 或客户端本地 | defineLocalNamespace | 同一客户端内解耦，不跨客户端 |

双端 namespace 加入 src/shared/network/init.lua，两端加载相同集合；服务端本地协议不加入双端聚合器。shared 下本地模块的源码仍对客户端可见，不得保存服务器私有数据；本地通信不跨 VM。

使用 fork 实际 API：definePacket({value=...})、defineQuery({request=..., response=...})。不要沿用旧文档 args / rets 简写来定义协议。

`ByteNetMax.struct` 必须在 defineNamespace / defineLocalNamespace 的回调内创建；共享 Schema 模块只导出 create 工厂，由各命名空间回调分别调用。禁止在模块顶层提前创建或跨命名空间缓存复用 struct：客户端依赖当前命名空间及创建顺序读取服务端字段布局。新项目接入此类定义时，须补充真实 ByteNet 双端初始化、不同本地协议加载顺序、ID 注册及 struct 字段顺序的验证；旧协议测试已随旧源码归档。

### 8.2 双端定义示例

Widget 是待创建系统的示例名，须先按 DataTypes 定义契约。

```lua
--!strict
-- src/shared/network/WidgetNetwork.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNetMax = require(ReplicatedStorage.Scripts.Packages.ByteNetMax)

return ByteNetMax.defineNamespace("Widget", function()
    local countData = ByteNetMax.struct({ count = ByteNetMax.uint32 })
    return {
        packets = {
            countChanged = ByteNetMax.definePacket({ value = countData }),
        },
        queries = {
            getCount = ByteNetMax.defineQuery({
                request = ByteNetMax.struct({ itemID = ByteNetMax.string }),
                response = ByteNetMax.struct({
                    code = ByteNetMax.uint16,
                    data = ByteNetMax.optional(countData),
                }),
            }),
        },
    }
end)
```

本人请求只传 itemID。服务端 `.listen(handler)` 的 handler 签名为 `(request, player)`，player 来自网络层。handler 仍需 Validate.args 和 Player 类别检查。

```lua
-- 客户端 DataController 内
local result = Network.Widget.queries.getCount.invoke({ itemID = itemID })
-- 服务端负责同步的 Controller / Service 内
Network.Widget.packets.countChanged.sendTo({ count = count }, player)
```

### 8.3 服务端本地定义示例

```lua
--!strict
-- src/server-storage/network/WidgetInternal.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ByteNetMax = require(ReplicatedStorage.Scripts.Packages.ByteNetMax)

return ByteNetMax.defineLocalNamespace("WidgetInternal", function()
    return {
        packets = {},
        queries = {
            getCount = ByteNetMax.defineQuery({
                request = ByteNetMax.struct({
                    player = ByteNetMax.inst,
                    itemID = ByteNetMax.string,
                }),
                response = ByteNetMax.struct({
                    code = ByteNetMax.uint16,
                    data = ByteNetMax.optional(ByteNetMax.struct({
                        count = ByteNetMax.uint32,
                    })),
                }),
            }),
        },
    }
end)
```

ByteNetMax.inst 是库的传输类型，不表示业务可接受任意 Instance：DataTypes 仍声明 Player，handler 验证 Player 类别。

```lua
-- 其他服务端系统只依赖协议，不依赖 WidgetService
local result = WidgetInternal.queries.getCount.invokeToLocal({
    player = player,
    itemID = itemID,
})
```

本地 query handler 接收 `(request, nil)`，没有网络层注入的玩家，因此请求必须显式携带 player。客户端本地协议同样使用 defineLocalNamespace，本人数据操作一般由数据层管理 LocalPlayer 上下文。

### 8.4 调用和时序约束

- 所有方法使用点：`.listen`、`.sendTo`、`.invoke`、`.sendToLocal`、`.invokeToLocal`，不能使用冒号。
- 事件用 packet.sendToLocal，问答用 query.invokeToLocal。后者直调第一个 listener；不应注册多个处理者，不会自动等待服务就绪。
- 本地路径不序列化、不执行 schema 运行时校验，仍须 Validate.args。直接调用不会自动阻止 handler 内部 yield，原子提交必须自行保证无 yield。
- 本地 namespace 不注册跨端 packet/query，也不占跨端 ID 池；跨端 packet 与 query 各有有限 u8 ID 池，拆 namespace 不扩容。
- 优先具体 struct / array；unknown 仅用于明确的通用数据或本地闭包边界，不能代替业务类型设计。
- 网络定义只声明协议，不 require Manager / Controller / Service / ServerClass 等业务实现，不修改存档、不执行业务初始化。
- 初始化先建立监听；服务端在监听就绪后的玩家接入或运行阶段调用，客户端在满足就绪条件的 start 或运行阶段调用。
- 网络超时不等于未执行；付费、抽取、领奖等操作按业务凭证幂等处理。

## 九、存档、资源与付费

UserDataSystem 是存档公共入口。调用 getData 前了解其契约，不能猜测返回的是业务数据还是 Profile 包装对象。ProfileStore 管会话和持久化。

持久化映射使用 string key，包含道具、货币、权益和兑换记录。顺序数组可以保留索引；纯内存且不落盘的缓存可按用途用 Player / number key。

变更先写回 profile.Data 对应数据，再同步客户端并发本地事件。写回内存 profile 不等于每次直接调用 DataStore；不能离场时才补写业务变化。

资源通过 ResourceService.condition / execute / transact 统一编排，操作字符串用分号分隔操作、逗号分隔参数，例如 `hasCurrency,1001,500`、`addCurrency,1001,100`。ResourceService 经本地协议调用，不 require 业务实现。

传统 execute / transact 不保证自动回滚；需要原子消耗与发放时使用明确的 prepare / commit / notify 协议，提交段无 yield，不凭 transact 名称推断事务性。

购买、抽取、兑换、领奖由服务端校验实际调用者及条件；客户端标价、概率展示、成功动画不是发货依据。超时重试保留原业务凭证，防止重复扣费或发奖。

GoodsRouteConfig 必须仅服务器可见。客户端只获取必要的展示信息或裁剪后的业务结果，不接收整张路由表。迁移要同时核查全部消费者，不能仅移动文件造成读取失败。

## 十、配置管道

配置链：configSource Excel / CSV → tools/config-puller/pull_config.py + sources.json → JSON / Luau → Rojo。区域密度和蛋池权重由 EggSpawnRegions.csv、EggSpawnPool.csv 导出到 ServerStorage.Scripts.EggSpawn。

新增表时明确源文件、sheet、字段类型、唯一键和输出位置；源文件与生成内容同时维护。公开配置输出 src/shared/config，由 src/shared/tools/ConfigHelper.lua 读取。私有配置必须指定服务端输出，禁止将兑换码、保底规则或商品路由同步给客户端。

旧模型、UI、动画、特效与编辑器资源均已归档。新项目按实际需要增加资产目录及 Rojo 映射，资源路径和加载公共入口须明确，不依赖旧 place 中的同名实例。不要仅为满足旧工具的输入而恢复已废弃表。

## 十一、新增功能步骤

### 服务端系统

1. 定义职责、协议、真实依赖及适用层级，明确网络、对象管理、状态、存档和清理分别由谁负责，不重复保存权威状态。
2. 在 DataTypes 定义请求、载荷、状态和存档类型，按需更新 ProfileTemplate。
3. 实现 Manager 生命周期入口；按系统需要选择 Controller / Service、ServerClass / BaseClass 及纯算法模块，不固定层数或强制 Service。全部收参函数完成 Validate.args 与 Player 校验。
4. 跨系统建 XxxInternal；跨端建 XxxNetwork 并加入共享聚合器。
5. ServerMain 注册依赖，确认先监听后调用。
6. 验证进场、退出、关闭、失败、超时及重复调用，必要的项目级契约写入 lemon.md。

### UI 面板

1. 创建 ScreenGui，确认名称、ResetOnSpawn 与层级。
2. 在 DataTypes 定义 State / Actions / Window / Panel 等公共类型。
3. 创建独立 DataController，管理业务与网络，并接入启动生命周期。
4. 创建 Controller / Window，遵循框架注入、一次性绑按钮和订阅清理。
5. 在 ui/config.lua 注册，不在通用框架硬编码业务。
6. 验证首次显示、反复开关、隐藏期间同步、重新打开、失败提示与清理。

## 十二、验证与交付检查

按改动选验证。文档变更不宣称运行已测试；业务变更不能只靠构建通过宣称玩法正常。

```powershell
luau-lsp analyze --sourcemap=sourcemap.json --definitions=.vscode/globalTypes.d.lua src/
rojo build -o build/game.rbxl
```

需要时更新 sourcemap。ConfigHelper 推断有历史诊断，但不能把新增错误都当误报。tools 中测试各自要求本地 Luau、Python harness 或 Studio Script / LocalScript，先核对环境与数据影响。

当前项目验证：

```powershell
python tools/run-framework-startup-tests.py build/luau-tools/luau.exe
python tools/config-puller/pull_config.py
rojo sourcemap default.project.json --output sourcemap.json
rojo build default.project.json -o build/game.rbxlx
```

启动测试核对服务端仅启用区域刷蛋、客户端入口、配置清单、空协议聚合器与 Rojo 映射。该测试不连接 Studio、不访问存档。新增业务后需随接线更新测试，不能继续用空项目测试证明玩法正确。构建验证不能替代 Studio 联机和场景验证。

- [ ] 无禁用全局、跨业务内部依赖、通用能力内部访问。
- [ ] 服务端分层符合职责需要，未强制套用固定层数；对象、状态、网络、存档和清理归属明确，基类无反向实现依赖。
- [ ] BaseClass / ServerClass / ClientClass 统一采用第 4.4 节 rawget 表式继承，new 造类、newObject 造实例，实例状态隔离，多层覆盖与销毁链正确。
- [ ] 玩家接口使用 Player 并校验类别，实际调用者不能由客户端替换。
- [ ] 服务端全部收参函数 Validate.args，字段、权限和业务约束齐全。
- [ ] 公共类型集中 DataTypes，文件标注与命名符合规范。
- [ ] Profile 映射 string key，变更及时写回，退出先结算后释放数据。
- [ ] ByteNet API 正确，调用使用点，本地与跨端 handler 玩家来源正确。
- [ ] 接口职责单一，查询和操作只传递必要数据；事件仅包含消费该业务事实所需信息，无整份状态或配置的冗余传输。
- [ ] 通用与系统业务错误归属清晰；系统错误前缀和号段独立，Codes / Messages 与调用方处理一致，无跨系统借码或笼统错误码掩盖具体业务失败。
- [ ] 就绪顺序明确，不把并行 init 当成顺序完成。
- [ ] UI 独立 DataController，Controller 无业务网络，Window 无业务逻辑。
- [ ] 私有配置仅服务器可见，源文件与生成内容一致。
- [ ] 涉及的失败、超时、重复调用、清理完成必要验证。
- [ ] 如实报告文档更新、代码修改、验证结果和遗留事项。

## 十三、已知实现差距（不是例外）

当前已接入区域刷蛋并拼好静态界面，存档系统、业务调度器和 UI 行为尚待接入。上述通用架构约定需在新增对应能力时落实，不能宣称骨架已提供这些能力。

Validate 的 expected 仍比较 typeof；Player 参数必须另行检查 IsA("Player")。动态校验及配置加载边界仍含 any，业务接口不得据此省略具体类型。保留的第三方库未做全库整改，默认不会 require 或运行。

ConfigHelper 保留按名称查找配置 ModuleScript 后动态 require 的实现；当前 luau-lsp 对该调用报告 `Unknown require: unsupported path`。这是保留工具的静态路径解析限制，刷蛋入口不会加载它；不能据此宣称全量静态检查已通过。新增配置接入时应单独验证真实加载路径与数据契约。

## 十四、规范维护与代码导航

项目只保留 lemon.md 与 AGENTS.md 两个项目 Markdown，职责不同：lemon.md 是唯一完整规范；AGENTS.md 是 AI 工作入口，只要求读取并遵守 lemon.md。新增或调整架构约定只修改 lemon.md；仅规范文件位置或入口指引变化时修改 AGENTS.md。不向 AGENTS.md 复制具体规则，也不另建重复规范、概览或系统 Markdown。

| 要核对的事实 | 查阅位置 |
|---|---|
| 工具版本与映射 | aftman.toml / default.project.json |
| 服务端入口 | src/server/ServerMain.server.lua（当前为空） |
| 客户端入口 | src/client/Main.client.lua（当前为空） |
| UI | assets/pony-ui 中的静态 Rojo 资产直接映射至 StarterGui。MainGui 与 currencyGui 默认显示，弹窗在 Studio 中切换 Enabled 即可预览。动态列表模板直接置于列表下，Visible 默认为 false。 |
| 双端协议 | src/shared/network/init.lua（当前为空） |
| 服务端内部协议 | src/server-storage/network |
| 公共类型、枚举、校验与错误 | src/shared/tools/DataTypes.lua / Validate.lua / ErrorCodes.lua |
| 配置输入、输出与读取工具 | tools/config-puller/sources.json / configSource / src/shared/tools/ConfigHelper.lua |
| 启动验证 | tools/run-framework-startup-tests.py |

迁移到其他游戏时，更新第三节的工程快照与第十三节的实现差距，保留通用禁止事项、职责边界、Player / DataTypes 契约和验证要求。第三方参考文档只用于查库 API，不能替代本项目的命名与架构规则。

## 十五、Git 与协作

未要求提交时不自行提交。提交信息格式沿用仓库约定：

```text
<type>: <简短描述>

<详细说明>

Co-Authored-By: Codex Opus 5 <noreply@anthropic.com>
```

type 为 feat / fix / refactor / docs / test / chore。现有 PR 描述末尾约定：

```text
🤖 Generated with [Codex](https://claude.com/claude-code)
```

交付必须区分“规则已确定”“文档已更新”“代码已整改”“运行已验证”。发现规则与结构不符时明确报告，不静默放宽边界。

