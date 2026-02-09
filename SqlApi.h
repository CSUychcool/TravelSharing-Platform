#ifndef SQLAPI_H
#define SQLAPI_H

#include <QObject>
#include <QQmlEngine>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QCryptographicHash>
#include <QVariantList> // 用于存放多条攻略信息

// 注册结果结构体（QML可接收）
struct RegisterResult {
    Q_GADGET

    // 2. 用 Q_PROPERTY 暴露属性，QML 才能访问 success 和 reason
    Q_PROPERTY(bool success MEMBER success READ getSuccess CONSTANT)
    Q_PROPERTY(QString reason MEMBER reason READ getReason CONSTANT)

public:
    bool success;
    QString reason;

    // 可选：添加读取函数（Q_PROPERTY 的 READ 对应，增强兼容性）
    bool getSuccess() const { return success; }
    QString getReason() const { return reason; }

};
Q_DECLARE_METATYPE(RegisterResult)

struct StrategyInfo {
    Q_GADGET
    // ========== 原有属性（保留不动，兼容最火攻略） ==========
    Q_PROPERTY(int id MEMBER id READ getId CONSTANT)
    Q_PROPERTY(QString city MEMBER city READ getCity CONSTANT)
    Q_PROPERTY(QString content MEMBER content READ getContent CONSTANT)
    Q_PROPERTY(int heat MEMBER heat READ getHeat CONSTANT) // 保留heat，兼容旧功能

    // ========== 新增属性（社区页面所需，不影响旧功能） ==========
    Q_PROPERTY(QString title MEMBER title READ getTitle CONSTANT) // 攻略标题
    Q_PROPERTY(QString category MEMBER category READ getCategory CONSTANT) // 攻略分类
    Q_PROPERTY(QString publishTime MEMBER publishTime READ getPublishTime CONSTANT) // 发布时间
    Q_PROPERTY(int hotScore MEMBER hotScore READ getHotScore CONSTANT) // 热度（与heat映射，冗余字段，方便理解）
    Q_PROPERTY(bool isCollected MEMBER isCollected READ getIsCollected CONSTANT) // 收藏状态

public:
    // 原有成员变量（保留）
    int id;
    QString city;
    QString content;
    int heat;

    // 新增成员变量
    QString title;
    QString category;
    QString publishTime;
    int hotScore; // 与heat对应数据库hot_score，兼容旧功能
    bool isCollected;

    // 原有读取函数（保留）
    int getId() const { return id; }
    QString getCity() const { return city; }
    QString getContent() const { return content; }
    int getHeat() const { return heat; }

    // 新增读取函数
    QString getTitle() const { return title; }
    QString getCategory() const { return category; }
    QString getPublishTime() const { return publishTime; }
    int getHotScore() const { return hotScore; }
    bool getIsCollected() const { return isCollected; }
};
Q_DECLARE_METATYPE(StrategyInfo) // 注册到元对象系统


class SqlApi : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit SqlApi(QObject *parent = nullptr);

    // 核心：暴露登录状态（NOTIFY 绑定 loginStatusChanged 信号）
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loginStatusChanged)
    Q_PROPERTY(QString currentUser READ currentUser NOTIFY loginStatusChanged)
    Q_PROPERTY(QString currentNickname READ currentNickname NOTIFY loginStatusChanged)
    // 新增：当前用户ID（整数类型，供QML调用）
    Q_PROPERTY(int currentUserId READ currentUserId NOTIFY loginStatusChanged)


    // 禁止拷贝/移动（QObject本身也禁用，显式声明更安全）
    SqlApi(const SqlApi&) = delete;
    SqlApi& operator=(const SqlApi&) = delete;
    SqlApi(SqlApi&&) = delete;
    SqlApi& operator=(SqlApi&&) = delete;

    // 析构函数：手动关闭数据库，避免析构顺序问题
    ~SqlApi() override {
        if (m_db.isOpen()) {
            m_db.close();
            qInfo() << "SqlApi析构：数据库已关闭";
        }
    }

    // 初始化数据库（程序启动时调用）
    Q_INVOKABLE bool initDB();

    // 登录接口（QML调用：账号+密码）
    Q_INVOKABLE bool login(const QString& username, const QString& password);

    // 注册接口（QML调用：账号+密码+昵称）
    Q_INVOKABLE RegisterResult registerUser(const QString& username,
                                            const QString& password,
                                            const QString& nickname);

    // 退出登录（QML调用）
    Q_INVOKABLE void logout();

    // 3. 新增：QML调用的“获取最火攻略”方法
    Q_INVOKABLE void getHotStrategies();

    // 新增：获取当前用户的收藏列表
    Q_INVOKABLE void getMyCollections();
    // 新增：删除指定收藏
    Q_INVOKABLE void deleteCollection(int collectId);
    // 新增：获取当前用户的详细信息（昵称/注册时间等）
    Q_INVOKABLE void getUserInfo();
    Q_INVOKABLE void collectStrategy(int strategyId, const QString& userName);


    // 属性getter
    bool isLoggedIn() const { return m_isLoggedIn; }
    QString currentUser() const { return m_currentUser; }
    QString currentNickname() const { return m_currentNickname; }

    // 新增：筛选攻略（按城市/分类）
    Q_INVOKABLE void filterStrategies(const QString& filterCity, const QString& filterCategory);

    // 新增：发布攻略
    Q_INVOKABLE void publishStrategy(const QString& userId, const QString& title,
                                     const QString& city, const QString& content,
                                     const QString& category);
    // 新增：QML调用的“获取所有不重复城市”方法
    Q_INVOKABLE void getAllCities();
    // 新增：获取当前用户ID的读取方法
    int currentUserId() const { return m_currentUserId; }

    Q_INVOKABLE bool updateUserNickname(int userId, const QString &newNickname);

    // ========== 新增：changePassword 函数声明（关键） ==========
    Q_INVOKABLE bool changePassword(int userId, const QString &oldPwd, const QString &newPwd);



signals:
    void loginStatusChanged(); // 登录状态变化信号
    void loginFailed(const QString& reason); // 登录失败提示信号
    void dbError(const QString& errorMsg); // 数据库错误信号
    // 4. 新增：攻略加载完成信号（传递给QML的攻略列表）
    // 注意：用QVariantList存放StrategyInfo（QML可直接遍历）
    void hotStrategiesLoaded(const QVariantList &strategies);
    void strategiesLoaded(const QVariantList& strategies); // 筛选结果信号
    void citiesLoaded(const QStringList &cityList); // 城市列表加载完成信号
    // 新增：我的收藏加载完成信号
    void myCollectionsLoaded(const QVariantList& collections);
    // 新增：用户信息加载完成信号
    void userInfoLoaded(const QVariantMap& userInfo);
    void routesLoaded(const QVariantList& routes); // 我的路线加载完成
    void teamLoaded(const QVariantList& members);  // 我的队伍加载完成
    void friendsLoaded(const QVariantList& friends); // 好友列表加载完成
    void chatRecordsLoaded(const QVariantList& records); // 聊天记录加载完成
    void messageSent(bool success); // 消息发送结果
    void mySignatureLoaded(const QString& signature); // 获取当前用户签名成功
    void signatureUpdated(bool success); // 修改签名结果
    void friendDeleted(bool success, const QString& tip); // 删除好友结果
    void friendAdded(bool success, const QString& tip); // 添加好友结果（之前已声明，此处确认）


    // 行程相关方法（数据库交互）
public slots:
    void getMyRoutes();               // 获取当前用户的路线
    void getMyTeam();                 // 获取当前用户的队伍
    void addRoute(const QString& routeName, const QString& routeDetail); // 新增路线
    void addTeamMember(const QString& memberName); // 新增队员
    void removeTeamMember(int memberId);           // 移除队员（根据member_id）
    void getMyFriends(); // 获取当前用户的好友列表
    void getChatRecords(int friendUserId); // 获取与指定好友的聊天记录
    void sendMessage(int receiverId, const QString& content); // 发送消息
    void getMySignature(); // 获取当前用户的个性签名
    void updateMySignature(const QString& newSignature); // 修改当前用户的个性签名
    void deleteFriend(int friendUserId); // 根据好友ID删除好友
    void addFriend(const QString& friendNickname); // 添加好友（之前已声明，此处确认）


private:

    // 内部工具方法：密码MD5加密
    QString encryptPassword(const QString& pwd);

    // 内部工具方法：执行SQL查询（防注入）
    QSqlQuery execQuery(const QString& sql, const QVariantMap& params = QVariantMap());

    // 内部工具方法：执行SQL更新（增/删/改，防注入）
    bool execUpdate(const QString& sql, const QVariantMap& params = QVariantMap());

    // 新增：私有成员变量 - 存储当前用户ID（整数类型，默认0表示未登录）
    int m_currentUserId = 0;

    // 成员变量
    QSqlDatabase m_db;          // 数据库连接
    bool m_isLoggedIn = false;  // 登录状态
    QString m_currentUser;      // 当前登录账号
    QString m_currentNickname;  // 当前登录用户昵称
    Q_INVOKABLE RegisterResult m_Register;


};

#endif // SQLAPI_H
