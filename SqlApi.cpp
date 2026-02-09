#include "SqlApi.h"

SqlApi::SqlApi(QObject *parent)
    : QObject{parent}
{
    initDB();
}



bool SqlApi::initDB()
{

    qInfo() << "===== SqlApi::initDB() 开始 =====";
    QString connName = "SqlApi_DB_Connection";

    // 1. 先强制清理旧连接（解决"仍在使用"警告）
    if (QSqlDatabase::contains(connName)) {
        QSqlDatabase oldDb = QSqlDatabase::database(connName);
        if (oldDb.isOpen()) {
            oldDb.close(); // 先关闭连接
            qInfo() << "关闭旧连接：" << connName;
        }
        // 延迟移除（避免查询还在使用）
        QSqlDatabase::removeDatabase(connName);
        qInfo() << "移除旧连接：" << connName;
    }

    // 2. 重新创建连接，强制赋值参数（逐行确认）
    m_db = QSqlDatabase::addDatabase("QMYSQL", connName);
    // 手动硬编码参数（排除变量赋值问题）
    m_db.setHostName("127.0.0.1");    // 明确赋值，不要用变量
    m_db.setPort(3306);               // 明确端口
    m_db.setDatabaseName("travelInfo");// 明确数据库名
    m_db.setUserName("root");         // 明确用户名
    m_db.setPassword("123456");       // 明确密码

    // 3. 打印赋值后的参数（验证是否真的设置成功）
    qInfo() << "赋值后 Host：" << m_db.hostName();
    qInfo() << "赋值后 Port：" << m_db.port();
    qInfo() << "赋值后 DB Name：" << m_db.databaseName();
    qInfo() << "赋值后 User：" << m_db.userName();

    // 4. 检查驱动是否真的能加载
    qInfo() << "Qt识别的驱动列表：" << QSqlDatabase::drivers();
    qInfo() << "是否支持QMYSQL：" << QSqlDatabase::isDriverAvailable("QMYSQL");

    // 5. 打开数据库
    bool openOk = m_db.open();
    qInfo() << "m_db.open() 结果：" << openOk;
    qInfo() << "打开失败原因：" << m_db.lastError().text();

    if (!openOk) {
        emit dbError("数据库连接失败：" + m_db.lastError().text());
        return false;
    }
    return true;
}


bool SqlApi::login(const QString &username, const QString &password)
{
    // 1. 空值校验（原有逻辑，不变）
    if (username.isEmpty() || password.isEmpty()) {
        emit loginFailed("账号/密码不能为空");
        return false;
    }

    // 2. 密码加密（原有逻辑，不变）
    QString encryptPwd = encryptPassword(password);

    // 3. 查询用户（防注入）【核心修改1：SQL中新增 user_id 字段查询】
    QString sql = R"(
        SELECT user_id, username, nickname FROM t_user  -- 新增：查询 user_id
        WHERE username = :username AND password = :pwd AND account_status = '正常'
    )";
    QVariantMap params;
    params[":username"] = username;
    params[":pwd"] = encryptPwd;

    QSqlQuery query = execQuery(sql, params);
    // 错误：之前重复执行了 query.exec()，现在去掉冗余判断，直接用 query.isActive()（原有逻辑，不变）
    if (!query.isActive()) {
        emit loginFailed("数据库查询异常：" + query.lastError().text());
        return false;
    }

    // 4. 验证结果（原有逻辑，仅新增 user_id 赋值）
    if (query.next()) {
        // 登录成功：更新状态【核心修改2：新增读取并保存 user_id】
        m_isLoggedIn = true;
        m_currentUserId = query.value("user_id").toInt(); // 读取整数类型的 user_id 并保存
        m_currentUser = query.value("username").toString(); // 原有逻辑，不变
        m_currentNickname = query.value("nickname").toString(); // 原有逻辑，不变
        emit loginStatusChanged();
        return true;
    } else {
        emit loginFailed("账号或密码错误"); // 原有逻辑，不变
        return false;
    }
}


// SqlApi.cpp 中 registerUser 方法优化（增加日志，排查问题）
RegisterResult SqlApi::registerUser(const QString &username, const QString &password, const QString &nickname)
{
    RegisterResult result;
    result.success = false;
    result.reason = "初始化失败";

    // 1. 先检查数据库是否打开
    if (!m_db.isOpen()) {
        result.reason = "数据库未连接，无法注册";
        qCritical() << "注册失败：数据库未打开";
        return result;
    }

    // 2. 前端基础校验（兜底）
    if (username.isEmpty() || password.isEmpty() || nickname.isEmpty()) {
        result.reason = "所有字段不能为空！";
        return result;
    }
    if (password.length() < 6) {
        result.reason = "密码长度不能少于6位！";
        return result;
    }

    // 3. 检查账号是否已存在（修正判断逻辑）
    QString checkSql = "SELECT username FROM t_user WHERE username = :username";
    QVariantMap checkParams;
    checkParams[":username"] = username;
    qDebug() << "检查账号 SQL：" << checkSql << "参数：" << checkParams;

    QSqlQuery checkQuery = execQuery(checkSql, checkParams);

    // 正确判断：用 isActive() 判断 SQL 是否执行成功（等价于 exec() 返回值）
    if (!checkQuery.isActive()) {
        result.reason = "查询账号是否存在失败：" + checkQuery.lastError().text();
        qCritical() << "注册失败：" << result.reason;
        return result;
    }

    // 正确判断：用 next() 判断是否存在该账号（next() 返回 true 表示有有效记录，即账号已存在）
    if (checkQuery.next()) {
        result.reason = "账号已存在，请更换账号！";
        return result;
    }

    // 4. 加密密码
    QString encryptPwd = encryptPassword(password);

    // 5. 插入新用户（原有逻辑不变，可保留日志）
    QString insertSql = R"(
        INSERT INTO t_user (username, password, nickname, register_time, account_status)
        VALUES (:username, :pwd, :nickname, NOW(), '正常')
    )";
    QVariantMap insertParams;
    insertParams[":username"] = username;
    insertParams[":pwd"] = encryptPwd;
    insertParams[":nickname"] = nickname;

    bool insertSuccess = execUpdate(insertSql, insertParams);
    if (insertSuccess) {
        result.success = true;
        result.reason = "注册成功，请登录！";
        qInfo() << "注册成功：账号" << username;
    } else {
        result.reason = "注册失败：" + m_db.lastError().text();
        qCritical() << "注册失败：插入用户失败，" << result.reason;
    }

    return result;
}


void SqlApi::logout()
{
    // 1. 重置登录状态
    m_isLoggedIn = false;
    m_currentUserId = 0;
    m_currentNickname = "";
    m_currentUser = "";

    // 2. 发射信号，通知QML端状态变化（核心！）
    emit loginStatusChanged();

    qDebug() << "用户已退出登录";
}

void SqlApi::getHotStrategies()
{
    QVariantList strategyList;

    if (!m_db.isOpen()) {
        qCritical() << "获取最火攻略失败：数据库未连接";
        emit hotStrategiesLoaded(strategyList);
        return;
    }

    // 原有SQL（已修正为数据库实际字段）
    QString sql = "SELECT strategy_id, city, content, hot_score FROM t_strategy ORDER BY hot_score DESC LIMIT 10";
    QVariantMap params;

    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取最火攻略失败：" << query.lastError().text();
        emit hotStrategiesLoaded(strategyList);
        return;
    }

    while (query.next()) {
        StrategyInfo strategy;
        // 原有赋值（保留，兼容最火攻略）
        strategy.id = query.value("strategy_id").toInt();
        strategy.city = query.value("city").toString();
        strategy.content = query.value("content").toString();
        strategy.heat = query.value("hot_score").toInt(); // 原有heat属性，正常赋值

        // 新增：给hotScore赋值（与heat一致，不影响旧功能，支持新功能）
        strategy.hotScore = strategy.heat;

        strategyList.append(QVariant::fromValue(strategy));
    }

    qInfo() << "成功获取" << strategyList.count() << "条最火攻略";
    emit hotStrategiesLoaded(strategyList);
}

// 1. 获取当前用户的收藏列表（关联collect表和t_strategy表）
void SqlApi::getMyCollections() {
    QVariantList collections;
    // 校验：未登录/数据库未连接则返回空
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit myCollectionsLoaded(collections);
        return;
    }

    // SQL：关联收藏表和攻略表，获取当前用户的收藏详情
    QString sql = R"(
        SELECT c.collect_id, s.strategy_id, s.title, s.content, c.collect_time, s.category
        FROM t_collection c
        JOIN t_strategy s ON c.strategy_id = s.strategy_id
        WHERE c.user_id = :user_id
        ORDER BY c.collect_time DESC
    )";
    QVariantMap params{{":user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取我的收藏失败：" << query.lastError().text();
        emit myCollectionsLoaded(collections);
        return;
    }

    // 遍历结果，封装为QML可识别的结构
    while (query.next()) {
        QVariantMap col;
        col["collectId"] = query.value("collect_id").toInt(); // 收藏ID（用于删除）
        col["type"] = query.value("category").toString();     // 攻略类型（分类）
        col["title"] = query.value("title").toString();       // 攻略标题
        col["desc"] = query.value("content").toString();      // 攻略内容
        col["time"] = query.value("collect_time").toString(); // 收藏时间
        collections.append(col);
    }
    emit myCollectionsLoaded(collections);
}

// 2. 删除指定收藏（根据collect_id）
void SqlApi::deleteCollection(int collectId) {
    if (!m_db.isOpen() || collectId <= 0) return;

    QString sql = "DELETE FROM t_collection  WHERE collect_id = :collect_id";
    QVariantMap params{{":collect_id", collectId}};
    bool success = execUpdate(sql, params);

    if (success) {
        qInfo() << "删除收藏成功（ID：" << collectId << "）";
        getMyCollections(); // 删除后自动刷新收藏列表
    } else {
        qCritical() << "删除收藏失败（ID：" << collectId << "）：" << m_db.lastError().text();
    }
}

// 3. 获取当前用户的详细信息（替换QML模拟数据）
void SqlApi::getUserInfo() {
    QVariantMap userInfo;
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit userInfoLoaded(userInfo);
        return;
    }

    // SQL：查询当前用户的信息
    QString sql = "SELECT username, nickname, register_time, account_status FROM t_user WHERE user_id = :user_id";
    QVariantMap params{{":user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (query.isActive() && query.next()) {
        userInfo["username"] = query.value("username").toString();
        userInfo["nickname"] = query.value("nickname").toString();
        userInfo["registerTime"] = query.value("register_time").toString();
        userInfo["accountStatus"] = query.value("account_status").toString();
    }
    emit userInfoLoaded(userInfo);
}

void SqlApi::collectStrategy(int strategyId, const QString& userName)
{
    // 1. 前置校验：数据库未连接/攻略ID无效/用户名为空，直接返回
    if (!m_db.isOpen() || strategyId <= 0 || userName.isEmpty()) {
        qCritical() << "收藏失败：数据库未连接或参数无效";
        return;
    }

    // 第一步：先查询用户ID（通过用户名获取 user_id，因为收藏表存的是 user_id 而非用户名）
    int userId = 0;
    QSqlQuery userIdQuery(m_db);
    userIdQuery.prepare("SELECT user_id FROM t_user WHERE username = :username");
    userIdQuery.bindValue(":username", userName);
    if (!userIdQuery.exec() || !userIdQuery.next()) {
        qCritical() << "收藏失败：未查询到该用户（" << userName << "）的ID";
        return;
    }
    userId = userIdQuery.value("user_id").toInt();

    // 第二步：查询该用户是否已收藏该攻略
    QSqlQuery checkQuery(m_db);
    checkQuery.prepare("SELECT collect_id FROM t_collection  WHERE user_id = :user_id AND strategy_id = :strategy_id");
    checkQuery.bindValue(":user_id", userId);
    checkQuery.bindValue(":strategy_id", strategyId);
    checkQuery.exec();

    if (checkQuery.next()) {
        // 已收藏：执行删除操作（取消收藏）
        int collectId = checkQuery.value("collect_id").toInt();
        QSqlQuery deleteQuery(m_db);
        deleteQuery.prepare("DELETE FROM t_collection  WHERE collect_id = :collect_id");
        deleteQuery.bindValue(":collect_id", collectId);
        if (deleteQuery.exec()) {
            qInfo() << "取消收藏成功：攻略ID" << strategyId << "，用户ID" << userId;
        } else {
            qCritical() << "取消收藏失败：" << deleteQuery.lastError().text();
        }
    } else {
        // 未收藏：执行插入操作（新增收藏）
        QSqlQuery insertQuery(m_db);
        insertQuery.prepare(R"(
            INSERT INTO t_collection  (user_id, strategy_id, collect_time)
            VALUES (:user_id, :strategy_id, NOW())
        )");
        insertQuery.bindValue(":user_id", userId);
        insertQuery.bindValue(":strategy_id", strategyId);
        if (insertQuery.exec()) {
            qInfo() << "收藏成功：攻略ID" << strategyId << "，用户ID" << userId;
        } else {
            qCritical() << "收藏失败：" << insertQuery.lastError().text();
        }
    }
}

void SqlApi::filterStrategies(const QString& filterCity, const QString& filterCategory) {
    QVariantList strategyList;
    if (!m_db.isOpen()) {
        qCritical() << "筛选攻略失败：数据库未连接";
        emit strategiesLoaded(strategyList);
        return;
    }

    // 构造筛选SQL
    QString sql = "SELECT strategy_id, title, content, city, category, publish_time, hot_score FROM t_strategy";
    QVariantMap params;
    QString whereClause;

    if (filterCity != "全部") {
        whereClause += " city = :city";
        params[":city"] = filterCity;
    }
    if (filterCategory != "全部") {
        whereClause += QString("%1 category = :category").arg(whereClause.isEmpty() ? "" : " AND");
        params[":category"] = filterCategory;
    }
    if (!whereClause.isEmpty()) sql += " WHERE " + whereClause;
    sql += " ORDER BY publish_time DESC";

    QSqlQuery query = execQuery(sql, params);
    if (!query.isActive()) {
        qCritical() << "筛选攻略失败：" << query.lastError().text();
        emit strategiesLoaded(strategyList);
        return;
    }

    while (query.next()) {
        StrategyInfo strategy;
        // 原有属性赋值（兼容最火攻略）
        strategy.id = query.value("strategy_id").toInt();
        strategy.city = query.value("city").toString();
        strategy.content = query.value("content").toString();
        strategy.heat = query.value("hot_score").toInt(); // 保留heat赋值

        // 新增属性赋值（社区页面所需）
        strategy.title = query.value("title").toString();
        strategy.category = query.value("category").toString();
        strategy.publishTime = query.value("publish_time").toString();
        strategy.hotScore = query.value("hot_score").toInt(); // 新的hotScore属性

        // 收藏状态判断
        QString collectSql = "SELECT COUNT(*) FROM t_collection WHERE user_id = :user AND strategy_id = :sid";
        QVariantMap collectParams{{":user", m_currentUser}, {":sid", strategy.id}};
        QSqlQuery collectQuery = execQuery(collectSql, collectParams);
        strategy.isCollected = collectQuery.next() && collectQuery.value(0).toInt() > 0;

        strategyList.append(QVariant::fromValue(strategy));
    }

    qInfo() << "筛选到" << strategyList.count() << "条攻略";
    emit strategiesLoaded(strategyList);
}


void SqlApi::publishStrategy(const QString &userId, const QString &title, const QString &city, const QString &content, const QString &category)
{
    if (!m_db.isOpen()) {
        qCritical() << "发布攻略失败：数据库未连接";
        return;
    }

    // 插入SQL（发布时间用NOW()，初始热度0）
    QString sql = R"(
        INSERT INTO t_strategy (user_id, title, content, city, category, publish_time, hot_score)
        VALUES (:user, :title, :content, :city, :category, NOW(), 0)
    )";
    QVariantMap params{
        {":user", userId}, {":title", title}, {":content", content},
        {":city", city}, {":category", category}
    };

    qDebug()<<"sql:"<<sql<<"params"<<params;

    bool success = execUpdate(sql, params);
    success ? qInfo() << "发布攻略成功：" << title :
        qCritical() << "发布攻略失败：" << m_db.lastError().text();
}

void SqlApi::getAllCities()
{
    QStringList cityList; // 存储不重复的城市列表
    if (!m_db.isOpen()) {
        qCritical() << "获取城市列表失败：数据库未连接";
        emit citiesLoaded(cityList);
        return;
    }

    // SQL：查询t_strategy表中所有不重复的城市（DISTINCT去重）
    QString sql = "SELECT DISTINCT city FROM t_strategy ORDER BY city ASC";
    QSqlQuery query = execQuery(sql);

    if (!query.isActive()) {
        qCritical() << "获取城市列表失败：" << query.lastError().text();
        emit citiesLoaded(cityList);
        return;
    }

    // 遍历查询结果，存入城市列表
    while (query.next()) {
        QString city = query.value("city").toString();
        if (!city.isEmpty()) { // 过滤空城市
            cityList.append(city);
        }
    }

    qInfo() << "成功获取" << cityList.count() << "个不重复城市";
    emit citiesLoaded(cityList);
}


bool SqlApi::updateUserNickname(int userId, const QString &newNickname)
{
    // 1. 检查数据库是否已连接
    if (!m_db.isOpen()) {
        emit dbError("数据库未连接，无法修改昵称！");
        return false;
    }

    // 2. 检查用户ID和新昵称是否有效
    if (userId <= 0 || newNickname.trimmed().isEmpty()) {
        emit dbError("用户ID无效或昵称为空，无法修改！");
        return false;
    }

    // 3. 编写SQL语句，更新用户昵称（匹配你的数据库表结构）
    QSqlQuery updateQuery(m_db);
    // 注意：表名 t_user、用户ID字段 user_id、昵称字段 nickname 请与你的实际表结构一致
    updateQuery.prepare("UPDATE t_user SET nickname = :new_nickname WHERE user_id = :user_id");
    updateQuery.bindValue(":new_nickname", newNickname.trimmed()); // 去除首尾空格
    updateQuery.bindValue(":user_id", userId);

    // 4. 执行SQL并处理错误
    if (!updateQuery.exec()) {
        QString errorMsg = "修改昵称失败：" + updateQuery.lastError().text();
        emit dbError(errorMsg);
        qDebug() << errorMsg;
        return false;
    }

    // 5. 更新成功：同步本地缓存的昵称（可选，优化本地显示）
    m_currentNickname = newNickname.trimmed();
    qDebug() << "昵称修改成功，用户ID：" << userId << "，新昵称：" << newNickname.trimmed();

    // 6. 重新加载用户信息（可选，确保QML端用户信息实时更新）
    getUserInfo();

    return true;
}

// ========== 新增：changePassword 函数实现（关键） ==========
bool SqlApi::changePassword(int userId, const QString &oldPwd, const QString &newPwd)
{
    // 1. 检查数据库连接
    if (!m_db.isOpen()) {
        emit dbError("数据库未连接，无法修改密码！");
        return false;
    }

    // ========== 关键修改：对输入的明文原密码进行 MD5 加密（和注册时保持一致） ==========
    QString oldPwdEncrypted; // 加密后的原密码
    // 1.1 转换明文为 QByteArray（MD5 加密需要字节数组格式）
    QByteArray oldPwdBytes = oldPwd.toUtf8();
    // 1.2 进行 MD5 加密（如果注册时用的是 SHA1，就把 QCryptographicHash::Md5 改为 QCryptographicHash::Sha1）
    QByteArray oldPwdHash = QCryptographicHash::hash(oldPwdBytes, QCryptographicHash::Md5);
    // 1.3 转换为 16 进制字符串（数据库中存储的加密密码一般是 16 进制格式）
    oldPwdEncrypted = oldPwdHash.toHex();

    // 2. 先校验原密码（此时用加密后的原密码和数据库中的加密密码对比）
    QSqlQuery checkQuery(m_db);
    checkQuery.prepare("SELECT password FROM t_user WHERE user_id = :user_id");
    checkQuery.bindValue(":user_id", userId);
    if (!checkQuery.exec()) {
        emit dbError("校验原密码失败：" + checkQuery.lastError().text());
        return false;
    }

    // 3. 判断原密码是否存在且匹配
    QString storedPwdEncrypted; // 数据库中存储的加密密码
    if (checkQuery.next()) {
        storedPwdEncrypted = checkQuery.value("password").toString(); // 数据库中的加密密码
    } else {
        emit dbError("用户不存在，无法修改密码！");
        return false;
    }

    // ========== 关键修改：对比 加密后的原密码 和 数据库中的加密密码 ==========
    if (oldPwdEncrypted != storedPwdEncrypted) {
        emit dbError("原密码输入错误！");
        return false;
    }

    // ========== 额外：新密码也需要加密后再存入数据库（和注册时保持一致） ==========
    QString newPwdEncrypted;
    QByteArray newPwdBytes = newPwd.toUtf8();
    QByteArray newPwdHash = QCryptographicHash::hash(newPwdBytes, QCryptographicHash::Md5);
    newPwdEncrypted = newPwdHash.toHex();

    // 4. 更新新密码（存入加密后的新密码）
    QSqlQuery updateQuery(m_db);
    updateQuery.prepare("UPDATE t_user SET password = :new_pwd WHERE user_id = :user_id");
    updateQuery.bindValue(":new_pwd", newPwdEncrypted); // 存入加密后的新密码
    updateQuery.bindValue(":user_id", userId);

    if (!updateQuery.exec()) {
        emit dbError("修改密码失败：" + updateQuery.lastError().text());
        return false;
    }

    // 5. 修改成功
    qDebug() << "密码修改成功，用户ID：" << userId;
    return true;
}

// SqlApi.cpp

// ========== 1. 获取当前用户的路线 ==========
void SqlApi::getMyRoutes() {
    QVariantList routes;
    // 校验：未登录/数据库未连接则返回空
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit routesLoaded(routes);
        return;
    }

    // 查询当前用户的路线（对应t_trip_route表）
    QString sql = R"(
        SELECT route_name, route_detail
        FROM t_trip_route
        WHERE user_id = :user_id
        ORDER BY create_time DESC
    )";
    QVariantMap params{{":user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取我的路线失败：" << query.lastError().text();
        emit routesLoaded(routes);
        return;
    }

    // 封装数据为QML可识别的结构
    while (query.next()) {
        QVariantMap route;
        route["routeName"] = query.value("route_name").toString();   // 路线名称
        route["routeContent"] = query.value("route_detail").toString(); // 路线详情
        routes.append(route);
    }
    emit routesLoaded(routes); // 通知QML更新模型
}


// ========== 2. 获取当前用户的队伍 ==========
void SqlApi::getMyTeam() {
    QVariantList members;
    // 校验：未登录/数据库未连接则返回空
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit teamLoaded(members);
        return;
    }

    // 查询当前用户的队伍（对应t_trip_member表）
    QString sql = R"(
        SELECT member_id, member_name
        FROM t_trip_member
        WHERE user_id = :user_id
        ORDER BY add_time DESC
    )";
    QVariantMap params{{":user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取我的队伍失败：" << query.lastError().text();
        emit teamLoaded(members);
        return;
    }

    // 封装数据（包含member_id，用于后续删除）
    while (query.next()) {
        QVariantMap member;
        member["memberId"] = query.value("member_id").toInt();     // 队员ID（删除用）
        member["memberName"] = query.value("member_name").toString(); // 队员名称
        members.append(member);
    }
    emit teamLoaded(members); // 通知QML更新模型
}


// ========== 3. 新增路线 ==========
void SqlApi::addRoute(const QString& routeName, const QString& routeDetail) {
    // 校验：未登录/参数为空则跳过
    if (!m_db.isOpen() || m_currentUserId == 0 || routeName.trimmed().isEmpty()) {
        return;
    }

    // 插入新路线到t_trip_route表
    QString sql = R"(
        INSERT INTO t_trip_route (user_id, route_name, route_detail, create_time)
        VALUES (:user_id, :route_name, :route_detail, NOW())
    )";
    QVariantMap params;
    params[":user_id"] = m_currentUserId;
    params[":route_name"] = routeName.trimmed();
    params[":route_detail"] = routeDetail.trimmed();

    bool success = execUpdate(sql, params);
    if (success) {
        qInfo() << "新增路线成功：" << routeName;
        getMyRoutes(); // 新增后自动刷新路线列表
    } else {
        qCritical() << "新增路线失败：" << m_db.lastError().text();
    }
}


// ========== 4. 新增队员 ==========
void SqlApi::addTeamMember(const QString& memberName) {
    // 校验：未登录/参数为空则跳过
    if (!m_db.isOpen() || m_currentUserId == 0 || memberName.trimmed().isEmpty()) {
        return;
    }

    // 插入新队员到t_trip_member表
    QString sql = R"(
        INSERT INTO t_trip_member (user_id, member_name, add_time)
        VALUES (:user_id, :member_name, NOW())
    )";
    QVariantMap params;
    params[":user_id"] = m_currentUserId;
    params[":member_name"] = memberName.trimmed();

    bool success = execUpdate(sql, params);
    if (success) {
        qInfo() << "新增队员成功：" << memberName;
        getMyTeam(); // 新增后自动刷新队伍列表
    } else {
        qCritical() << "新增队员失败：" << m_db.lastError().text();
    }
}


// ========== 5. 移除队员 ==========
void SqlApi::removeTeamMember(int memberId) {
    // 校验：未登录/队员ID无效则跳过
    if (!m_db.isOpen() || m_currentUserId == 0 || memberId <= 0) {
        return;
    }

    // 根据member_id删除t_trip_member表中的记录
    QString sql = R"(
        DELETE FROM t_trip_member
        WHERE member_id = :member_id AND user_id = :user_id
    )";
    QVariantMap params;
    params[":member_id"] = memberId;
    params[":user_id"] = m_currentUserId;

    bool success = execUpdate(sql, params);
    if (success) {
        qInfo() << "移除队员成功：member_id=" << memberId;
        getMyTeam(); // 移除后自动刷新队伍列表
    } else {
        qCritical() << "移除队员失败：" << m_db.lastError().text();
    }
}

// SqlApi.cpp

// ========== 1. 获取当前用户的好友列表（关联t_friend和t_user表） ==========
void SqlApi::getMyFriends() {
    QVariantList friends;
    // 校验：未登录/数据库未连接
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit friendsLoaded(friends);
        return;
    }

    // SQL：关联t_friend和t_user，获取好友的昵称、签名
    QString sql = R"(
        SELECT
            t_user.user_id AS friend_user_id,  -- 好友的user_id（用于后续查聊天记录）
            t_user.nickname AS name,           -- 好友昵称
            t_user.signature AS content        -- 好友个性签名
        FROM t_friend
        JOIN t_user ON t_friend.friend_user_id = t_user.user_id
        WHERE t_friend.user_id = :current_user_id  -- 当前登录用户的user_id
        ORDER BY t_friend.add_time DESC
    )";
    QVariantMap params{{":current_user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取好友列表失败：" << query.lastError().text();
        emit friendsLoaded(friends);
        return;
    }

    // 封装好友数据（QML可识别的结构）
    while (query.next()) {
        QVariantMap friendItem;
        friendItem["userId"] = query.value("friend_user_id").toInt(); // 好友ID（关键）
        friendItem["name"] = query.value("name").toString();          // 好友昵称
        friendItem["content"] = query.value("content").toString();    // 好友签名
        friends.append(friendItem);
    }
    emit friendsLoaded(friends);
}


// ========== 2. 获取与指定好友的聊天记录（从t_chat_record表） ==========
void SqlApi::getChatRecords(int friendUserId) {
    QVariantList records;
    // 校验：未登录/好友ID无效
    if (!m_db.isOpen() || m_currentUserId == 0 || friendUserId == 0) {
        emit chatRecordsLoaded(records);
        return;
    }

    // SQL：查询当前用户与好友的双向聊天记录，按时间排序
    QString sql = R"(
        SELECT
            sender_id,    -- 发送者ID（区分自己/对方消息）
            content,      -- 消息内容
            send_time     -- 发送时间
        FROM t_chat_record
        WHERE
            (sender_id = :current_user_id AND receiver_id = :friend_user_id)  -- 我发的
            OR
            (sender_id = :friend_user_id AND receiver_id = :current_user_id)  -- 对方发的
        ORDER BY send_time ASC  -- 按时间正序排列
    )";
    QVariantMap params{
        {":current_user_id", m_currentUserId},
        {":friend_user_id", friendUserId}
    };
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive()) {
        qCritical() << "获取聊天记录失败：" << query.lastError().text();
        emit chatRecordsLoaded(records);
        return;
    }

    // 封装聊天记录（标记是否是自己发的消息）
    while (query.next()) {
        QVariantMap record;
        record["isSelf"] = (query.value("sender_id").toInt() == m_currentUserId); // 自己发的？
        record["content"] = query.value("content").toString();                    // 消息内容
        record["time"] = query.value("send_time").toString();                      // 发送时间
        records.append(record);
    }
    emit chatRecordsLoaded(records);
}


// ========== 3. 发送消息（插入t_chat_record表） ==========
void SqlApi::sendMessage(int receiverId, const QString& content) {
    // 校验：未登录/接收者无效/内容为空
    if (!m_db.isOpen() || m_currentUserId == 0 || receiverId == 0 || content.trimmed().isEmpty()) {
        emit messageSent(false);
        return;
    }

    // SQL：插入新消息
    QString sql = R"(
        INSERT INTO t_chat_record (sender_id, receiver_id, content, send_time)
        VALUES (:sender_id, :receiver_id, :content, NOW())
    )";
    QVariantMap params{
        {":sender_id", m_currentUserId},
        {":receiver_id", receiverId},
        {":content", content.trimmed()}
    };

    bool success = execUpdate(sql, params);
    if (success) {
        emit messageSent(true);
        getChatRecords(receiverId); // 发送后自动刷新聊天记录
    } else {
        emit messageSent(false);
        qCritical() << "发送消息失败：" << m_db.lastError().text();
    }
}

// SqlApi.cpp

// ========== 获取当前用户的个性签名 ==========
void SqlApi::getMySignature() {
    QString signature = "";
    // 校验：未登录/数据库未连接
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit mySignatureLoaded(signature);
        return;
    }

    // SQL：查询当前用户的signature字段
    QString sql = R"(
        SELECT signature FROM t_user WHERE user_id = :current_user_id
    )";
    QVariantMap params{{":current_user_id", m_currentUserId}};
    QSqlQuery query = execQuery(sql, params);

    if (!query.isActive() || !query.next()) {
        qCritical() << "获取个性签名失败：" << query.lastError().text();
        emit mySignatureLoaded(signature);
        return;
    }

    signature = query.value("signature").toString();
    emit mySignatureLoaded(signature);
}

// ========== 修改当前用户的个性签名 ==========
void SqlApi::updateMySignature(const QString& newSignature) {
    // 校验：未登录/数据库未连接/签名为空
    if (!m_db.isOpen() || m_currentUserId == 0) {
        emit signatureUpdated(false);
        return;
    }

    // SQL：更新t_user表的signature字段
    QString sql = R"(
        UPDATE t_user
        SET signature = :new_signature
        WHERE user_id = :current_user_id
    )";
    QVariantMap params{
        {":new_signature", newSignature.trimmed()},
        {":current_user_id", m_currentUserId}
    };

    bool success = execUpdate(sql, params);
    if (success) {
        qInfo() << "个性签名修改成功";
        // 修改后重新获取签名，同步界面
        getMySignature();
    } else {
        qCritical() << "个性签名修改失败：" << m_db.lastError().text();
    }
    emit signatureUpdated(success);
}

// SqlApi.cpp
void SqlApi::deleteFriend(int friendUserId) {
    // 校验：未登录/数据库未连接/好友ID无效
    if (!m_db.isOpen() || m_currentUserId == 0 || friendUserId == 0) {
        emit friendDeleted(false, "无法删除好友：参数无效！");
        return;
    }

    // 执行删除操作
    QString deleteSql = R"(
        DELETE FROM t_friend
        WHERE user_id = :current_user AND friend_user_id = :friend_user
    )";
    QSqlQuery query(m_db);
    query.prepare(deleteSql);
    query.bindValue(":current_user", m_currentUserId);
    query.bindValue(":friend_user", friendUserId);

    if (query.exec()) {
        emit friendDeleted(true, "删除好友成功！");
        getMyFriends(); // 删除成功后自动刷新好友列表
    } else {
        emit friendDeleted(false, "删除好友失败，请稍后重试！");
        qCritical() << "删除好友失败：" << query.lastError().text();
    }
}

void SqlApi::addFriend(const QString &friendNickname)
{
    // 校验1：未登录/数据库未连接/昵称为空
    if (!m_db.isOpen() || m_currentUserId == 0 || friendNickname.trimmed().isEmpty()) {
        emit friendAdded(false, "参数无效，请输入好友昵称！");
        return;
    }

    // 步骤1：根据昵称查询好友的user_id
    int friendUserId = 0;
    QString querySql = R"(
        SELECT user_id FROM t_user WHERE nickname = :friend_nickname
    )";
    QSqlQuery query(m_db);
    query.prepare(querySql);
    query.bindValue(":friend_nickname", friendNickname.trimmed());

    if (!query.exec() || !query.next()) {
        emit friendAdded(false, "未查询到该好友，请核对昵称！");
        qCritical() << "查询好友失败：" << query.lastError().text();
        return;
    }
    friendUserId = query.value("user_id").toInt();

    // 校验2：不能添加自己
    if (friendUserId == m_currentUserId) {
        emit friendAdded(false, "不能添加自己为好友！");
        return;
    }
    // 校验3：避免重复添加
    QString checkSql = R"(
        SELECT COUNT(*) FROM t_friend
        WHERE user_id = :current_user AND friend_user_id = :friend_user
    )";
    QSqlQuery checkQuery(m_db);
    checkQuery.prepare(checkSql);
    checkQuery.bindValue(":current_user", m_currentUserId);
    checkQuery.bindValue(":friend_user", friendUserId);

    if (!checkQuery.exec() || !checkQuery.next()) {
        emit friendAdded(false, "校验好友关系失败，请稍后重试！");
        qCritical() << "校验好友关系失败：" << checkQuery.lastError().text();
        return;
    }
    if (checkQuery.value(0).toInt() > 0) {
        emit friendAdded(false, "该好友已在你的列表中，无需重复添加！");
        return;
    }

    // 步骤2：插入t_friend表，完成添加
    QString insertSql = R"(
    INSERT INTO t_friend (user_id, friend_user_id, add_time)
    VALUES (:current_user, :friend_user, NOW())
)";
    QSqlQuery insertQuery(m_db);
    insertQuery.prepare(insertSql);
    insertQuery.bindValue(":current_user", m_currentUserId);
    insertQuery.bindValue(":friend_user", friendUserId);
    if (insertQuery.exec()) {
        emit friendAdded(true, "添加好友成功！");
        getMyFriends(); // 添加成功后自动刷新好友列表
    } else {
        emit friendAdded(false, "添加好友失败，请稍后重试！");
        qCritical() << "添加好友失败：" << insertQuery.lastError().text();
    }
}


QString SqlApi::encryptPassword(const QString &pwd)
{
    QByteArray pwdBytes = pwd.toUtf8();
    return QCryptographicHash::hash(pwdBytes, QCryptographicHash::Md5).toHex();
}

QSqlQuery SqlApi::execQuery(const QString &sql, const QVariantMap &params)
{
    QSqlQuery query(m_db);
    // 1. 先准备 SQL 并绑定参数
    bool prepareOk = query.prepare(sql);
    if (!prepareOk) {
        qCritical() << "SQL 预编译失败：" << query.lastError().text() << "SQL：" << sql;
        return query;
    }

    // 2. 绑定参数
    for (auto it = params.begin(); it != params.end(); ++it) {
        query.bindValue(it.key(), it.value());
    }

    // 3. 执行 SQL（这是判断 SQL 是否执行成功的关键！）
    bool execOk = query.exec();
    qDebug() << "SQL 执行结果：" << execOk << "（true=执行成功，false=执行失败）";
    qDebug() << "SQL 执行错误信息：" << query.lastError().text();

    // 注意：此时还未移动结果集，isValid() 必然为 false，无需打印
    return query;
}

bool SqlApi::execUpdate(const QString& sql, const QVariantMap& params) {
    if (!m_db.isOpen()) {
        qCritical() << "execUpdate失败：数据库未连接";
        return false;
    }

    QSqlQuery query(m_db);
    // 1. 预编译SQL是否失败
    if (!query.prepare(sql)) {
        QString errMsg = query.lastError().text();
        qCritical() << "SQL预编译失败：" << errMsg; // 打印query的错误信息
        return false;
    }

    // 2. 绑定参数
    for (auto it = params.begin(); it != params.end(); ++it) {
        query.bindValue(it.key(), it.value());
    }

    // 3. 执行SQL是否失败
    bool success = query.exec();
    if (!success) {
        QString errMsg = query.lastError().text();
        qCritical() << "SQL执行失败：" << errMsg; // 打印query的错误信息
        return false;
    }

    // 打印受影响行数，确认插入是否有效
    int affectedRows = query.numRowsAffected();
    qInfo() << "SQL执行成功，受影响行数：" << affectedRows;
    return true;
}





