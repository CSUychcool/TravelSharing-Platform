// StrategyPage.qml
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import ProjectExp

Item {
    width: parent.width
    height: parent.height

    // 路线数据模型（与C++的routesLoaded信号绑定）
    ListModel { id: routeModel }
    // 队伍数据模型（与C++的teamLoaded信号绑定）
    ListModel { id: teamModel }

    // ========== 核心修改1：监听页面可见性，可见时主动刷新数据 ==========
    onVisibleChanged: {
        // 当页面变为可见时，重新加载数据（切换页面时触发）
        if (visible) {
            // 延迟一小段时间，避免页面还未完全渲染导致的加载异常
            Qt.callLater(function() {
                SqlApi.getMyRoutes()
                SqlApi.getMyTeam()
            })
        }
    }

    // ========== 核心修改2：优化初始化逻辑，确保信号绑定+首次加载 ==========
    Component.onCompleted: {
        // 先绑定信号，再加载数据，避免数据先返回而信号未绑定导致丢失
        SqlApi.routesLoaded.connect(updateRouteModel)
        SqlApi.teamLoaded.connect(updateTeamModel)

        // 首次加载数据
        SqlApi.getMyRoutes()
        SqlApi.getMyTeam()
    }

    // 更新路线模型（接收C++的routesLoaded信号）
    function updateRouteModel(routes) {
        // 确保模型在主线程更新，避免渲染异常
        Qt.callLater(function() {
            routeModel.clear()
            routes.forEach(route => routeModel.append(route))
        })
    }

    // 更新队伍模型（接收C++的teamLoaded信号）
    function updateTeamModel(members) {
        // 确保模型在主线程更新，避免渲染异常
        Qt.callLater(function() {
            teamModel.clear()
            members.forEach(member => teamModel.append(member))
        })
    }


    // 主布局：TabBar + 内容区域
    ColumnLayout {
        anchors.fill: parent
        spacing: 0  // TabBar和内容区无缝衔接

        // 1. 顶部TabBar（切换“我的路线/我的队伍”）
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            background: Rectangle { color: "black"; border.color: "black" }

            TabButton {
                text: "我的路线"
                checked: true
            }
            TabButton {
                text: "我的队伍"
            }
        }

        // 2. 内容区域（与TabBar联动）
        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex  // 联动TabBar

            // ========== 页面1：我的路线 ==========
            Item {
                width: parent.width
                height: parent.height

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // 新增路线按钮
                    Button {
                        text: "新增路线"
                        background: Rectangle { color: "#409eff"; radius: 6 }
                        palette.buttonText: "white"
                        onClicked: routeDialog.open()
                        Layout.alignment: Qt.AlignRight
                    }

                    // 路线列表（绑定routeModel，添加无数据提示）
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        model: routeModel
                        clip: true



                        delegate: Rectangle {
                            width: parent.width
                            height: 100
                            color: "#f5f5f5"
                            radius: 8
                            border.color: "#eee"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                Text {
                                    text: model.routeName
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#333"
                                }
                                Text {
                                    text: model.routeContent
                                    font.pixelSize: 14
                                    color: "#666"
                                    wrapMode: Text.Wrap
                                    width: parent.width - 30
                                }
                            }
                        }
                    }
                }
            }

            // ========== 页面2：我的队伍 ==========
            Item {
                width: parent.width
                height: parent.height

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    // 新增队员按钮
                    Button {
                        text: "新增队员"
                        background: Rectangle { color: "#409eff"; radius: 6 }
                        palette.buttonText: "white"
                        onClicked: teamDialog.open()
                        Layout.alignment: Qt.AlignRight
                    }

                    // 队伍列表（绑定teamModel，添加无数据提示）
                    ListView {
                        id:listvieww
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10
                        model: teamModel
                        clip: true



                        delegate: Rectangle {
                            width: listvieww.width
                            height: 70
                            color: "#f5f5f5"
                            radius: 8
                            border.color: "#eee"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 10

                                Text {
                                    text: "队员：" + model.memberName
                                    font.pixelSize: 16
                                    color: "#333"
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: "移除"
                                    background: Rectangle { color: "#ff4d4d"; radius: 4 }
                                    palette.buttonText: "white"
                                    // 调用C++的removeTeamMember，传入队员ID
                                    onClicked: SqlApi.removeTeamMember(model.memberId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ========== 新增路线对话框 ==========
    Dialog {
        id: routeDialog
        title: "新增旅游路线"
        width: 400
        height: 280
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text { text: "路线名称"; font.pixelSize: 14; color: "#333" }
            TextField {
                id: routeName
                Layout.fillWidth: true
                placeholderText: "例如：桂林3日游"
                font.pixelSize: 14
            }

            Text { text: "路线详情"; font.pixelSize: 14; color: "#333" }
            TextArea {
                id: routeContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "输入详细的路线安排..."
                font.pixelSize: 14
            }
        }

        // 确认新增：调用C++的addRoute
        onAccepted: {
            if (routeName.text.trim() === "") return;
            SqlApi.addRoute(routeName.text.trim(), routeContent.text.trim())
            routeName.text = "";
            routeContent.text = "";
        }
    }

    // ========== 新增队员对话框 ==========
    Dialog {
        id: teamDialog
        title: "新增队员"
        width: 350
        height: 180
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text { text: "队员昵称"; font.pixelSize: 14; color: "#333" }
            TextField {
                id: memberName
                Layout.fillWidth: true
                placeholderText: "输入队员的昵称"
                font.pixelSize: 14
            }
        }

        // 确认新增：调用C++的addTeamMember
        onAccepted: {
            if (memberName.text.trim() === "") return;
            SqlApi.addTeamMember(memberName.text.trim())
            memberName.text = "";
        }
    }
}
