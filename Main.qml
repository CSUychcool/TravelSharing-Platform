import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes 1.15
import ProjectExp

Window {
    id:root
    width: 1000
    height: 800
    visible: true
    title: qsTr("旅游信息分享平台")

    // ========== 1. 全局登录状态管理（核心：双向感知C++端状态） ==========
    property bool loggedIn: SqlApi.isLoggedIn // 单向绑定C++端状态，自动更新
    property string currentUser: "" // 当前登录用户（可选，扩展用）

    // ==========2.登录页面（初始显示） ==========
    LoginPage{
        id: loginPage
    }

    // ========== 3. 主容器（登录成功后显示） ==========
    Item {
        id: mainContainer
        anchors.fill: parent
        visible: loggedIn // 已登录时显示，登录状态变化时自动隐藏/显示

        // ========== 3.1. 多界面容器：StackLayout（平级切换核心） ==========
        StackLayout {
            id: pageStack
            anchors.fill: parent
            anchors.bottomMargin: 60 // 给底部按钮组留空间

            // 界面索引枚举
            property int pageMain: 0      // 主界面
            property int pageNews: 1      // 消息页面
            property int pageMy: 2        // 我的界面（SelfPage）
            property int pageCommunity: 3 // 社区界面
            property int pageStrategy: 4  // 行程界面

            // ========== 各界面定义 ==========
            MainPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            NewsPage {
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height - 20
            }

            SelfPage {
                id: selfPage // 给SelfPage设置id，便于后续操作
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Filtrate {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            StrategyPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // 默认显示主界面
            currentIndex: pageStack.pageMain

            // ========== 核心：监听页面索引变化，切换到SelfPage时刷新数据 ==========
            onCurrentIndexChanged: {
                // 判断是否切换到了“我的”页面（SelfPage）
                if (currentIndex === pageStack.pageMy) {
                    // 确保已登录，才加载数据
                    if (loggedIn) {
                        console.log("切换到我的页面，重新加载用户信息和收藏");
                        // 主动触发C++端加载数据，SelfPage会监听信号并更新
                        // SqlApi.getUserInfo();
                        // SqlApi.getMyCollections();
                        // 无需手动布局，数据加载后SelfPage布局会自动更新
                    }
                }
            }
        }

        // ========== 2. 底部横向ButtonGroup（切换界面核心） ==========
        Rectangle {
            id: tabBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            color: "#f8f8f8"
            border.color: "#eee"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                ButtonGroup {
                    id: tabGroup
                    onCheckedButtonChanged: {
                        if (checkedButton) {
                            pageStack.currentIndex = checkedButton.tabIndex;
                        }
                    }
                }

                // 按钮通用样式
                component TabButton: Button {
                    property int tabIndex: -1
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    checkable: true
                    ButtonGroup.group: tabGroup
                    palette.buttonText: checked ? "#409eff" : "#666"
                    font.pixelSize: 14
                    background: Rectangle {
                        color: checked ? "#e6f7ff" : "transparent"
                    }
                }

                // 各功能按钮
                TabButton {
                    tabIndex: pageStack.pageMain
                    text: "首页"
                    checked: true
                }
                TabButton {
                    tabIndex: pageStack.pageNews
                    text: "消息"
                }
                TabButton {
                    tabIndex: pageStack.pageMy
                    text: "我的"
                }
                TabButton {
                    tabIndex: pageStack.pageCommunity
                    text: "社区"
                }
                TabButton {
                    tabIndex: pageStack.pageStrategy
                    text: "行程"
                }
            }
        }
    }

    // ========== 额外：监听登录状态变化，重置页面索引（可选，优化体验） ==========
    Connections {
        target: SqlApi
        onLoginStatusChanged: {
            // 退出登录时，重置StackLayout到首页，避免停留在SelfPage
            if (!SqlApi.isLoggedIn) {
                pageStack.currentIndex = pageStack.pageMain;
            }
        }
    }
}
