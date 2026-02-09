import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import ProjectExp

// 3. 我的界面（含用户信息/修改密码/我的收藏/个性签名设置）
Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    // 补充：页面可见性变化时刷新数据（新增加载个性签名）
    onVisibleChanged: {
        if (visible && SqlApi.isLoggedIn) {
            console.log("SelfPage显示，刷新数据");
            SqlApi.getUserInfo();
            SqlApi.getMyCollections();
            SqlApi.getMySignature(); // 新增：加载个性签名
        }
    }

    // ========== 替换模拟数据：动态加载真实用户信息 ==========
    property var userInfo: ({}) // 存储当前用户真实信息
    property string userSignature: "" // 新增：存储当前用户个性签名
    // 收藏数据模型（替换原模拟ListModel）
    ListModel {
        id: favoriteModel
    }

    // ========== 统一监听登录状态变化（合并重复逻辑，避免冲突） ==========
    Connections {
        target: SqlApi
        onLoginStatusChanged: {
            if (SqlApi.isLoggedIn) {
            } else {
                // 退出登录时，彻底清空数据
                userInfo = {};
                userSignature = ""; // 新增：清空个性签名
                favoriteModel.clear();
            }
        }
    }

    // ========== 连接C++信号：更新用户信息（移除forceLayout） ==========
    Connections {
        target: SqlApi
        onUserInfoLoaded: function(realUserInfo) {
            userInfo = realUserInfo;
            // 移除无效的 forceLayout 调用，布局会自动更新
        }
    }

    // ========== 新增：连接C++信号：更新个性签名 ==========
    Connections {
        target: SqlApi
        onMySignatureLoaded: function(signature) {
            userSignature = signature; // 同步C++返回的个性签名
        }
    }

    // ========== 新增：连接C++信号：个性签名修改结果 ==========
    Connections {
        target: SqlApi
        onSignatureUpdated: function(success) {
            if (success) {
                tipDialog.contentItem.text = "个性签名修改成功！";
                tipDialog.open();
            } else {
                tipDialog.contentItem.text = "个性签名修改失败，请稍后重试！";
                tipDialog.open();
            }
        }
    }

    // ========== 连接C++信号：更新我的收藏（移除forceLayout） ==========
    Connections {
        target: SqlApi
        onMyCollectionsLoaded: function(realCollections) {
            favoriteModel.clear(); // 先彻底清空旧数据
            realCollections.forEach(col => {
                favoriteModel.append({
                    collectId: col.collectId,
                    type: col.type,
                    title: col.title,
                    desc: col.desc,
                    time: col.time
                });
            });
            // 移除无效的 forceLayout 调用，布局会自动更新
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ========== 1. 顶部用户信息区（新增个性签名显示，无图片，根据登录状态显示） ==========
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: contentCol.implicitHeight + 40
            radius: 10
            color: "white"
            border.color: "#eee"

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                // 用户信息（居中）
                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 5

                    Text {
                        text: SqlApi.isLoggedIn ? (userInfo.nickname || "未知用户") : "未登录"
                        font.pixelSize: 18
                        font.bold: true
                        color: "#333"
                    }
                    Text {
                        visible: SqlApi.isLoggedIn
                        text: "账号：" + (userInfo.username || "")
                        font.pixelSize: 14
                        color: "#666"
                    }
                    Text {
                        visible: SqlApi.isLoggedIn
                        text: "注册时间：" + (userInfo.registerTime || "").replace("T", " ").replace(".000Z", "")
                        font.pixelSize: 14
                        color: "#666"
                    }
                    // 新增：个性签名显示
                    Text {
                        visible: SqlApi.isLoggedIn && userSignature.trim() !== ""
                        text: "个性签名：" + userSignature
                        font.pixelSize: 14
                        color: "#666"
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // 编辑按钮（居中，仅登录后显示）
                Button {
                    visible: SqlApi.isLoggedIn
                    Layout.alignment: Qt.AlignHCenter
                    text: "编辑"
                    font.pixelSize: 14
                    padding: 8
                    width: 80
                    background: Rectangle {
                        color: "green"
                        radius: 8
                    }
                    palette.text: "#409eff"
                    onPressed: background.color = "409eff"
                    onReleased: background.color = "green"
                    onClicked: editUserDialog.open();
                }
            }
        }

        // ========== 2. 中部功能区（无图标，原有功能不变） ==========
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 7

            // 功能1：用户信息详情
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                radius: 8
                color: "white"
                border.color: "#eee"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        userInfoDialog.title = "用户信息详情";
                        // 新增：用户信息详情中添加个性签名
                        userInfoDialog.contentItem.text =
                            "用户名：" + (userInfo.username || "未知") + "\n" +
                            "昵称：" + (userInfo.nickname || "未知") + "\n" +
                            "个性签名：" + (userSignature || "暂无个性签名") + "\n" +
                            "注册时间：" + (userInfo.registerTime || "未知").replace("T", " ").replace(".000Z", "") + "\n" +
                            "账号状态：" + (userInfo.accountStatus || "正常");
                        userInfoDialog.open();
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "用户信息详情"
                        font.pixelSize: 16
                        color: "#333"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                    Text {
                        text: ">"
                        font.pixelSize: 16
                        color: "#999"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // 功能2：修改密码
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                radius: 8
                color: "white"
                border.color: "#eee"
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: changePwdDialog.open();
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 10

                    Text {
                        text: "修改密码"
                        font.pixelSize: 16
                        color: "#333"
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                    Text {
                        text: ">"
                        font.pixelSize: 16
                        color: "#999"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }

            // 功能3：我的收藏（原有逻辑不变，已修复布局问题）
            ColumnLayout {
                id: collectionCol
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 15

                Text {
                    text: "我的收藏"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#333"
                    Layout.alignment: Qt.AlignLeft
                    Layout.bottomMargin: 10
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    background: Rectangle { color: "transparent" }

                    Column {
                        width: parent.width
                        spacing: 20
                        anchors.margins: 5

                        Repeater {
                            model: favoriteModel
                            delegate: Rectangle {
                                width: parent.width - 10
                                height: contentCol.height + 20
                                radius: 6
                                color: "white"
                                border.color: "#eee"
                                border.width: 1

                                MouseArea { /* 原有逻辑不变 */ }

                                Column {
                                    id: mcontentCol
                                    width: parent.width - 20 // 与收藏项的padding匹配
                                    spacing: 12

                                    // 1. 收藏标题（原有逻辑不变）
                                    Text {
                                        text: model.title
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: "#333"
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }

                                    // 2. 收藏描述（原有逻辑不变）
                                    Text {
                                        text: model.desc
                                        font.pixelSize: 12
                                        color: "#666"
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }

                                    // 横向布局（时间+类型+删除按钮，原有修复逻辑不变）
                                    RowLayout {
                                        Layout.fillWidth: true // 强制占满父容器宽度（关键！）
                                        spacing: 20

                                        // 收藏时间：固定宽度
                                        Text {
                                            text: model.time.replace("T", " ").replace(".000Z", "")
                                            font.pixelSize: 11
                                            color: "#999"
                                            Layout.preferredWidth: 120 // 固定宽度，不挤压
                                            wrapMode: Text.Wrap
                                        }

                                        // 收藏类型：固定宽度
                                        Text {
                                            text: model.type
                                            font.pixelSize: 11
                                            color: "#999"
                                            padding: 3
                                            Layout.preferredWidth: 80 // 固定宽度，不挤压
                                        }

                                        // 删除按钮：强制右对齐 + 固定尺寸
                                        Button {
                                            Layout.alignment: Qt.AlignRight // 固定右对齐
                                            Layout.preferredWidth: 60 // 固定按钮宽度
                                            Layout.preferredHeight: 25 // 固定按钮高度
                                            text: "删除"
                                            font.pixelSize: 11
                                            padding: 5
                                            background: Rectangle {
                                                color: "#f56c6c"
                                                radius: 8
                                            }
                                            palette.text: "white"
                                            onClicked: SqlApi.deleteCollection(model.collectId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ========== 3. 底部：退出登录按钮 ==========
        Button {
            visible: SqlApi.isLoggedIn
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 150
            Layout.preferredHeight: 45
            text: "退出登录"
            font.pixelSize: 16
            background: Rectangle {
                color: "#f56c6c"
                radius: 8
            }
            palette.text: "white"
            onPressed: background.color = "#e45656"
            onReleased: background.color = "#f56c6c"
            onClicked: {
                SqlApi.logout();
                userInfo = {};
                userSignature = ""; // 新增：清空个性签名
                favoriteModel.clear();
            }
        }
    }

    // ========== 对话框（扩展编辑用户信息对话框，新增个性签名设置） ==========
    Dialog {
        id: editUserDialog
        title: "编辑用户信息"
        width: 400
        height: 600 // 加高对话框，容纳个性签名
        modal: true
        closePolicy: Dialog.ClosePolicy.ManualClose
        standardButtons: Dialog.NoButton

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Text {
                text: "修改用户信息"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 20
                font.bold: true
                color: "#333"
            }

            // 原有：昵称修改
            Text { text: "昵称："; font.pixelSize: 14; color: "#333" }
            TextField {
                id: editNickname
                Layout.fillWidth: true
                text: userInfo.nickname || ""
                font.pixelSize: 14
                padding: 12
                background: Rectangle {
                    color: "#f5f5f5"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 8
                }
                focusPolicy: Qt.StrongFocus
                onFocusChanged: background.border.color = focus ? "#409eff" : "#ddd"
            }

            // 新增：个性签名修改
            Text { text: "个性签名："; font.pixelSize: 14; color: "#333" }
            TextArea {
                id: editSignature
                Layout.fillWidth: true
                Layout.preferredHeight: 80 // 固定高度
                text: userSignature || ""
                font.pixelSize: 14
                padding: 12
                wrapMode: TextEdit.Wrap // 自动换行
                verticalAlignment: TextEdit.AlignTop
                background: Rectangle {
                    color: "#f5f5f5"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 8
                }
                focusPolicy: Qt.StrongFocus
                onFocusChanged: background.border.color = focus ? "#409eff" : "#ddd"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    text: "确认"
                    font.pixelSize: 16
                    font.bold: true
                    background: Rectangle { color: "#409eff"; radius: 8 }
                    palette.buttonText: "white"
                    onPressed: background.color = "#3a8ee6"
                    onReleased: background.color = "#409eff"
                    onClicked: {
                        // 原有：昵称非空校验
                        if (editNickname.text.trim() === "") {
                            tipDialog.contentItem.text = "昵称不能为空！";
                            tipDialog.open();
                            return;
                        }

                        // 步骤1：更新昵称（原有逻辑）
                        userInfo.nickname = editNickname.text.trim();
                        SqlApi.updateUserNickname(SqlApi.currentUserId, editNickname.text.trim());

                        // 步骤2：更新个性签名（新增逻辑）
                        if (editSignature.text.trim() !== userSignature) {
                            SqlApi.updateMySignature(editSignature.text.trim());
                        }

                        // 关闭对话框
                        editUserDialog.close();
                        // 昵称修改成功提示（个性签名有单独提示）
                        tipDialog.contentItem.text = "昵称修改成功！";
                        tipDialog.open();
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    text: "取消"
                    font.pixelSize: 16
                    background: Rectangle { color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8 }
                    palette.buttonText: "#666"
                    onClicked: editUserDialog.close();
                }
            }
        }
    }

    Dialog {
        id: changePwdDialog
        title: "修改密码"
        width: 400
        height: 600
        modal: true
        closePolicy: Dialog.ClosePolicy.ManualClose
        standardButtons: Dialog.NoButton

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            Text {
                text: "修改账号密码"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 20
                font.bold: true
                color: "#333"
            }

            Text { text: "原密码："; font.pixelSize: 14; color: "#333" }
            TextField {
                id: oldPwd
                Layout.fillWidth: true
                echoMode: TextField.Password
                font.pixelSize: 14
                padding: 12
                background: Rectangle { color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8 }
                focusPolicy: Qt.StrongFocus
                onFocusChanged: background.border.color = focus ? "#409eff" : "#ddd"
            }

            Text { text: "新密码："; font.pixelSize: 14; color: "#333" }
            TextField {
                id: newPwd
                Layout.fillWidth: true
                echoMode: TextField.Password
                font.pixelSize: 14
                padding: 12
                background: Rectangle { color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8 }
                focusPolicy: Qt.StrongFocus
                onFocusChanged: background.border.color = focus ? "#409eff" : "#ddd"
            }

            Text { text: "确认新密码："; font.pixelSize: 14; color: "#333" }
            TextField {
                id: confirmPwd
                Layout.fillWidth: true
                echoMode: TextField.Password
                font.pixelSize: 14
                padding: 12
                background: Rectangle { color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8 }
                focusPolicy: Qt.StrongFocus
                onFocusChanged: background.border.color = focus ? "#409eff" : "#ddd"
            }

            Text {
                id: pwdTipText
                color: "#f56c6c"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: 25
                visible: false
                text: ""
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    text: "确认修改"
                    font.pixelSize: 16
                    font.bold: true
                    background: Rectangle { color: "#409eff"; radius: 8 }
                    palette.buttonText: "white"
                    onPressed: background.color = "#3a8ee6"
                    onReleased: background.color = "#409eff"
                    onClicked: {
                        let oldPassword = oldPwd.text.trim();
                        let newPassword = newPwd.text.trim();
                        let confirmPassword = confirmPwd.text.trim();
                        pwdTipText.visible = false;

                        if (oldPassword === "" || newPassword === "" || confirmPassword === "") {
                            pwdTipText.text = "所有字段不能为空！";
                            pwdTipText.visible = true;
                            return;
                        }
                        if (newPassword !== confirmPassword) {
                            pwdTipText.text = "两次输入的新密码不一致！";
                            pwdTipText.visible = true;
                            return;
                        }
                        if (newPassword.length < 6) {
                            pwdTipText.text = "密码长度不能少于6位！";
                            pwdTipText.visible = true;
                            return;
                        }

                        SqlApi.changePassword(SqlApi.currentUserId, oldPassword, newPassword);
                        changePwdDialog.close();
                        tipDialog.contentItem.text = "密码修改成功！";
                        tipDialog.open();
                        oldPwd.text = "";
                        newPwd.text = "";
                        confirmPwd.text = "";
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    text: "取消"
                    font.pixelSize: 16
                    background: Rectangle { color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8 }
                    palette.buttonText: "#666"
                    onClicked: {
                        changePwdDialog.close();
                        oldPwd.text = "";
                        newPwd.text = "";
                        confirmPwd.text = "";
                    }
                }
            }
        }
    }

    Dialog {
        id: userInfoDialog
        width: 300
        height: 250 // 加高对话框，容纳个性签名
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            id: infoText
            text: ""
            font.pixelSize: 14
            color: "#333"
            anchors.centerIn: parent
            wrapMode: Text.Wrap
        }
    }
    Dialog {
        id: favoriteDialog
        width: 300
        height: 150
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: ""
            font.pixelSize: 14
            anchors.centerIn: parent
            wrapMode: Text.Wrap
        }
    }
    Dialog {
        id: tipDialog
        width: 300
        height: 200
        standardButtons: Dialog.Ok
        modal: true
        contentItem: Text {
            text: ""
            font.pixelSize: 14
            anchors.centerIn: parent
        }
    }

    Connections {
        target: SqlApi
        function onDbError(errorMsg) {
            tipDialog.contentItem.text = errorMsg;
            tipDialog.open();
            console.log("数据库错误：", errorMsg);
        }
    }
}
