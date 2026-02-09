import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import ProjectExp  // 对应CMake/.pro的QML模块名

Item {
    width: parent.width
    height: parent.height
    signal loginSucceeded()

    id: loginpage
    visible: !SqlApi.isLoggedIn // 绑定SqlApi的登录状态



    Rectangle {
        id: loginPage
        anchors.fill: parent
        color: "#f5f5f5"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            width: 400

            // 标题
            Text {
                text: "旅游信息分享平台 - 登录"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 24
                font.bold: true
                color: "#333"
            }

            // 账号输入框
            TextField {
                id: txtAccount
                Layout.fillWidth: true
                placeholderText: "请输入账号"
                font.pixelSize: 14
                padding: 10
                background: Rectangle {
                    color: "gray"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 6
                }
            }

            // 密码输入框
            TextField {
                id: txtPwd
                Layout.fillWidth: true
                placeholderText: "请输入密码"
                font.pixelSize: 14
                padding: 10
                echoMode: TextField.Password
                background: Rectangle {
                    color: "gray"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 6
                }
            }

            // 登录提示弹窗
            Dialog {
                id: msgDialog
                width: 300
                height: 200
                standardButtons: Dialog.Ok
                modal: true

                contentItem: ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    anchors.margins: 0

                    Text {
                        id: dialogText
                        text: ""
                        font.pixelSize: 14
                        color: "#666"
                        Layout.alignment: Qt.AlignCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            // 登录/注册按钮行
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // 登录按钮（修改：调用C的login）
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    text: "登录"
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "#409eff"
                        radius: 6
                    }
                    palette.buttonText: "white"
                    onClicked: {
                        let loginSuccess = SqlApi.login(txtAccount.text.trim(), txtPwd.text.trim());
                        if (loginSuccess) {
                            // 登录成功：清空输入框+触发信号
                            txtAccount.text = "";
                            txtPwd.text = "";
                            loginSucceeded();
                        }
                    }
                }

                // 注册按钮
                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    text: "注册"
                    font.pixelSize: 16
                    background: Rectangle {
                        color: "#67c23a"
                        radius: 6
                    }
                    palette.buttonText: "white"
                    onClicked: {
                        // 打开注册弹窗并清空表单
                        regAccountTxt.text = "";
                        regPwdTxt.text = "";
                        regPwdConfirmTxt.text = "";
                        regNicknameTxt.text = "";
                        regTipText.visible = false;
                        regDialog.open();
                    }
                }
            }

            // 注册弹窗
            Dialog {
                id: regDialog
                width: 400
                height: 500 // 适配新布局，适当增高
                anchors.centerIn: parent
                modal: true
                closePolicy: Dialog.ClosePolicy.ManualClose
                // 去掉默认按钮，全部自定义（避免默认布局干扰）
                standardButtons: Dialog.NoButton

                contentItem: ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20 // 整体内边距，避免内容贴边
                    spacing: 20 // 元素之间的间距更宽松

                    // 1. 标题（居中+加粗）
                    Text {
                        text: "填写注册信息"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 20
                        font.bold: true
                        color: "#333"
                    }

                    // 2. 账号输入框（优化样式）
                    TextField {
                        id: regAccountTxt
                        Layout.fillWidth: true
                        placeholderText: "请设置账号（唯一）"
                        font.pixelSize: 14
                        padding: 12 // 输入框内边距，更舒适
                        background: Rectangle {
                            color: "#f5f5f5" // 浅灰背景，替代深灰
                            border.color: "#ddd"
                            border.width: 1
                            radius: 8 // 圆角更大，更美观
                        }
                        // 聚焦时高亮边框
                        focusPolicy: Qt.StrongFocus
                        onFocusChanged: {
                            background.border.color = focus ? "#409eff" : "#ddd"
                        }
                    }

                    // 3. 密码输入框
                    TextField {
                        id: regPwdTxt
                        Layout.fillWidth: true
                        placeholderText: "请设置密码"
                        font.pixelSize: 14
                        padding: 12
                        echoMode: TextField.Password
                        background: Rectangle {
                            color: "#f5f5f5"
                            border.color: "#ddd"
                            border.width: 1
                            radius: 8
                        }
                        onFocusChanged: {
                            background.border.color = focus ? "#409eff" : "#ddd"
                        }
                    }

                    // 4. 确认密码输入框
                    TextField {
                        id: regPwdConfirmTxt
                        Layout.fillWidth: true
                        placeholderText: "请确认密码"
                        font.pixelSize: 14
                        padding: 12
                        echoMode: TextField.Password
                        background: Rectangle {
                            color: "#f5f5f5"
                            border.color: "#ddd"
                            border.width: 1
                            radius: 8
                        }
                        onFocusChanged: {
                            background.border.color = focus ? "#409eff" : "#ddd"
                        }
                    }

                    // 5. 昵称输入框
                    TextField {
                        id: regNicknameTxt
                        Layout.fillWidth: true
                        placeholderText: "请设置昵称"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f5f5f5"
                            border.color: "#ddd"
                            border.width: 1
                            radius: 8
                        }
                        onFocusChanged: {
                            background.border.color = focus ? "#409eff" : "#ddd"
                        }
                    }

                    // 6. 注册提示文本（固定高度+居中）
                    Text {
                        id: regTipText
                        color: "#f56c6c" // 更柔和的红色
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 25 // 固定高度，避免布局跳动
                        visible: false
                        text: ""
                        wrapMode: Text.Wrap // 文字过长时自动换行
                    }

                    // 7. 按钮区域（确认+取消 同一行）
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15 // 按钮之间的间距

                        // 确认注册按钮（占比更大）
                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            text: "确认注册"
                            font.pixelSize: 16
                            font.bold: true
                            background: Rectangle {
                                color: "#409eff"
                                radius: 8
                            }
                            palette.buttonText: "white"
                            // 点击态效果
                            onPressed: {
                                background.color = "#3a8ee6"
                            }
                            onReleased: {
                                background.color = "#409eff"
                            }

                            onClicked: {
                                let account = regAccountTxt.text.trim();
                                let pwd = regPwdTxt.text.trim();
                                let pwdConfirm = regPwdConfirmTxt.text.trim();
                                let nickname = regNicknameTxt.text.trim();

                                regTipText.visible = false;

                                // 前端校验
                                if (account === "" || pwd === "" || pwdConfirm === "" || nickname === "") {
                                    regTipText.text = "所有字段不能为空！";
                                    regTipText.visible = true;
                                    return;
                                }
                                if (pwd !== pwdConfirm) {
                                    regTipText.text = "两次密码不一致！";
                                    regTipText.visible = true;
                                    return;
                                }
                                if (pwd.length < 6) {
                                    regTipText.text = "密码长度不能少于6位！";
                                    regTipText.visible = true;
                                    return;
                                }

                                // 调用注册接口
                                let regResult = SqlApi.registerUser(account, pwd, nickname);
                                if (regResult.success) {
                                    regDialog.close();
                                    msgDialog.title = "注册成功";
                                    dialogText.text = regResult.reason;
                                    msgDialog.open();
                                } else {
                                    regTipText.text = regResult.reason;
                                    regTipText.visible = true;
                                }
                            }
                        }

                        // 取消按钮
                        Button {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            text: "取消"
                            font.pixelSize: 16
                            background: Rectangle {
                                color: "#f5f5f5"
                                border.color: "#ddd"
                                border.width: 1
                                radius: 8
                            }
                            palette.buttonText: "#666"

                            onClicked: {
                                regDialog.close();
                            }
                        }
                    }
                }
            }
        }
    }

    // 监听SqlApi的登录失败信号（弹窗提示）
    Connections {
        target: SqlApi
        function onLoginFailed(reason) {
            msgDialog.title = "登录失败";
            dialogText.text = reason;
            msgDialog.open();
        }
    }

    // 监听数据库错误（可选，调试用）
    Connections {
        target: SqlApi
        function onDbError(errorMsg) {
            console.log("数据库状态：", errorMsg);
        }
    }
}
