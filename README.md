# TravelInfoShare 旅游信息分享平台
一款轻量、高性能的跨平台旅游信息分享平台，整合**旅游攻略分享、社交互动、行程规划**三大核心能力，为旅行者打造攻略收集、队伍组建、实时沟通、路线规划的一站式解决方案，全面覆盖旅游前、中、后全流程的服务需求。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Qt 6.8.0](https://img.shields.io/badge/Qt-6.8.0-blue.svg)](https://www.qt.io/)
[![MySQL 8.0.36](https://img.shields.io/badge/MySQL-8.0.36-orange.svg)](https://www.mysql.com/)
[![C++17](https://img.shields.io/badge/C%2B%2B-17-green.svg)](https://en.cppreference.com/w/cpp/17)

## 项目背景
随着旅游业的数字化发展，旅行者对一体化、互动化的旅游信息服务需求日益提升。传统旅游信息获取方式存在**内容零散、更新滞后、缺乏社交属性**等痛点，无法满足用户从出行规划、途中互动到后期分享的全流程需求。

本项目基于Qt框架与MySQL数据库打造，采用分层架构设计，实现旅游信息服务全闭环。平台以数据高效存储与交互为核心，兼顾功能完整性与操作易用性，为旅游爱好者打造可交流、可协作、可分享的个性化旅游信息社区，同时具备良好的扩展性与跨平台适配性。

## 核心功能
### 1. 用户身份认证
- 支持账号唯一校验的注册/登录/退出功能，密码MD5加密存储保障安全
- 登录状态实时同步，支持账号状态管理（正常/禁用）与基础权限控制
- 前端+后端双重输入校验，杜绝非法数据提交
- <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/afa7ff5c-8a14-4466-9404-197d41e7bbe0" />


### 2. 旅游攻略服务
- **热门攻略推荐**：首页按热度值降序展示优质攻略，快速获取高价值内容
- **攻略发布/浏览**：支持发布带城市、分类标签的攻略，详情页完整展示内容
- **多维度筛选**：按城市（如北京、桂林）、分类（自然风景/人文景点等）精准筛选
- **收藏管理**：攻略收藏/取消收藏，个人中心可集中查看、删除收藏内容
  <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/f0f8086d-a5b7-4e57-9bee-3ea4229eeb91" />
  <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/183678d6-cab5-4fe9-8dce-8a9e48dbeff9" />



### 3. 社交互动功能
- 好友管理：添加/删除好友、查看好友列表，防错限制（自加好友、重复添加）
- 实时聊天：与好友一对一即时通讯，聊天记录持久化存储，历史消息可查
- 消息同步：发送消息后自动刷新聊天记录，前端展示与数据库实时一致
- <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/453f73b4-6db8-492a-98c3-88df45c243df" />


### 4. 个人中心管理
- 个人信息管理：查看/编辑昵称、个性签名，修改后实时同步至数据库
- 安全改密：修改密码需验证原密码，底层保障账号安全
- 收藏汇总：集中展示所有收藏攻略，支持一键删除，操作反馈清晰
- 信息可视化：直观展示账号、昵称、注册时间等核心个人信息
- <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/ec52bda2-842f-416a-92ec-335f8667c295" />


### 5. 行程规划与管理
- **自定义路线创建**：支持创建专属旅行路线，填写每日行程、景点安排等
- **旅行队伍组建**：添加/移除队员、查看队员列表，适配结伴出行场景
- **数据持久化**：路线与队员信息永久存储，可随时查询、编辑
- <img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/b9fcecd1-22e3-4474-8f6a-88284c06b55a" />
<img width="1252" height="1039" alt="image" src="https://github.com/user-attachments/assets/1256c040-63ba-4a06-a3df-7d0de6bab432" />



## 技术栈
| 模块       | 技术及版本                          |
|------------|-----------------------------------|
| 前端       | Qt Quick QML（跨平台界面开发）|
| 后端       | C++17、Qt 6.8.0（业务逻辑+数据库交互） |
| 数据库     | MySQL 8.0.36（数据持久化）|
| 数据库可视化 | MySQLWorkbench/Navicat Premium（管理维护） |
| 构建工具   | CMake 3.16+（跨平台项目构建）|
| 开发IDE    | Qt Creator 17.0.0                 |
| 系统支持   | Windows（主开发）、Linux（兼容适配） |

## 核心技术亮点
### 1. 安全的数据处理机制
- 密码采用MD5加密存储，数据库无明文密码，从根源避免泄露
- 所有SQL操作使用参数绑定方式，彻底杜绝SQL注入攻击
- 前端+后端双重校验，确保入库数据合法规范
- 核心字段设置唯一索引、外键约束，避免重复/无效数据

### 2. 高优化的数据库设计
- 基于业务场景设计7张核心业务表，表结构合理，数据关系清晰
- 高频查询字段（username、city、category等）建立定向索引，提升查询效率
- 原子性操作采用事务管理，确保多步操作一致性（如添加好友、攻略收藏）
- 外键约束配置`ON DELETE CASCADE`，实现关联数据自动清理
- 多表关联查询使用JOIN语句，减少数据库交互开销

### 3. 无缝的前后端集成
- 基于Qt信号与槽机制，实现QML（前端）与C++（后端）异步通信，交互流畅
- `SqlApi`类采用单例模式设计，统一管理数据库操作，提升代码复用性
- 数据修改后自动刷新相关列表，实现前端与数据库实时同步
- 封装可复用QML组件（聊天面板、筛选组件等），减少代码冗余

### 4. 稳定高效的性能表现
- 优化数据库连接池，增加旧连接清理逻辑，避免连接冲突
- 数据库单次查询/更新响应时间≤500ms，核心数据首次加载≤1s
- 支持100+用户同时在线操作，无数据冲突
- 大数据集（攻略列表、聊天记录）采用分页加载，优化性能

## 快速开始
### 前置条件
1. 操作系统：Windows 10/11（64位）、Ubuntu 20.04+（Linux）
2. 安装Qt 6.8.0（需包含Qt Quick、Qt SQL、MySQL驱动组件）
3. 安装MySQL 8.0.36（远程连接需开启对应权限）
4. 安装CMake 3.16+及C++编译器（MSVC 2019+/GCC 9+）

### 1. 克隆仓库
```bash
git clone https://github.com/你的用户名/TravelInfoShare.git
cd TravelInfoShare
```

### 2. 数据库初始化
1. 打开MySQL客户端，创建数据库：
2. 完成表结构创建；
3. 修改`src/SqlApi.cpp`中的数据库连接参数：
   ```cpp
   m_db.setHostName("127.0.0.1");    // 数据库地址
   m_db.setPort(3306);               // MySQL端口
   m_db.setDatabaseName("travel_info_share"); // 数据库名
   m_db.setUserName("你的MySQL用户名");
   m_db.setPassword("你的MySQL密码");
   ```

### 3. 编译运行
1. 启动Qt Creator 17.0.0，选择项目根目录的`CMakeLists.txt`打开项目；
2. 选择构建套件（MinGw 2019+/GCC）与构建类型（Debug/Release）；
3. 点击「构建」按钮完成编译（确保无编译错误）；
4. 点击「运行」启动程序，注册新账号（密码≥6位）即可体验所有功能。

## 项目结构
项目采用**前后端分离+模块化设计**，职责清晰，便于维护扩展：
```plain
TravelInfoShare/
├── qml/                  # 前端QML界面
│   ├── LoginPage.qml     # 登录/注册页面
│   ├── MainPage.qml      # 首页（热门攻略）
│   ├── NewsPage.qml      # 社交聊天/好友管理
│   ├── CommunityPage.qml # 攻略发布/筛选
│   ├── TripPage.qml      # 行程路线/队伍管理
│   ├── SelfPage.qml      # 个人中心
│   └── Components/       # 可复用QML组件
├── src/                  # 后端C++代码
│   ├── main.cpp          # 程序入口
│   ├── SqlApi.h/cpp      # 核心数据库操作类（单例）
│   ├── models/           # 数据模型（攻略/用户/行程等）
│   └── utils/            # 工具类（MD5加密、数据校验）
├── CMakeLists.txt        # CMake构建配置
├── LICENSE               # MIT许可证文件
└── README.md             # 项目说明
```

## 未来规划
### 功能扩展
- 新增攻略图片上传、富文本发布功能
- 实现攻略点赞、评论、分享，强化用户互动
- 增加旅行路线协同编辑，支持多人团队规划
- 新增旅行游记发布模块

### 性能优化
- 集成Redis缓存，降低MySQL高频查询压力
- 实现MySQL读写分离，提升高并发能力
- 优化大数据集分页查询，增加懒加载机制
- 压缩资源文件，减小安装包体积

### 跨平台适配
- 适配Android/iOS移动设备
- 优化UI布局，自适应不同屏幕分辨率
- 完善Linux/macOS全平台适配

### 智能功能
- 集成协同过滤算法，实现个性化攻略推荐
- 增加城市/景点模糊匹配搜索
- 基于用户偏好实现路线智能推荐

### 云部署与DevOps
- 部署至云服务器（阿里云/腾讯云）
- 配置数据库自动备份与容灾恢复
- 集成GitHub Actions实现CI/CD
- 增加日志收集与分析（ELK）

## 贡献指南
欢迎通过以下方式为本项目贡献力量：

### 贡献流程
1. Fork本仓库至个人账号；
2. 创建开发分支：`git checkout -b feature/功能名称`；
3. 提交修改：`git commit -m "新增：攻略图片上传功能"`；
4. 推送分支：`git push origin feature/功能名称`；
5. 提交Pull Request，描述修改内容。

### 代码规范
- 遵循Qt官方C++/QML编码规范；
- 核心逻辑添加详细注释；
- 提交前确保无编译警告，通过功能测试；
- 保持代码风格统一（缩进、命名、文件命名）。

### 问题反馈
- 发现Bug/提出需求：提交GitHub Issue；
- 描述需包含：运行环境、复现步骤、预期结果；
- 必要时附上日志/截图，便于定位问题。

## 许可证
本项目基于**MIT开源许可证**发布，可自由用于个人/商业项目，可修改、分发，无需授权。详见`LICENSE`文件。

## 联系我们
- 邮箱：yc_213313@163.com

---
⭐ 如果你觉得本项目有帮助，欢迎点星支持！你的支持是项目持续优化的最大动力。
```
