import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    // 对外属性：好友列表模型
    property ListModel friendsModel: null
    // 对外属性：当前选中的好友
    property var currentFriend: null
    // 对外信号（必须在根Item下）
       signal friendSelected(var friend)
       signal friendDeleteRequested(var friendInfo) // 核心：信号声明

    ListView{
        id: newsView
        width: parent.width
        height: parent.height
        // 明确锚点，避免父级引用为null
        anchors {
            left: parent.left
            leftMargin: 20
            top: parent.top
            bottom: parent.bottom
        }
        clip: true
        spacing: 5
        model: friendsModel
        // 按钮组：确保好友选中状态互斥
        ButtonGroup{id: buttonGroup}

        // 好友项代理
        delegate: Item {
            width: newsView.width * 0.9
            height: 100
            anchors.horizontalCenter: parent.horizontalCenter
            id: rootDelegate // 明确代理根ID，避免parent为null
            // 暂存当前好友数据
            property var currentFriendData: null

            // 长按检测：500ms触发删除菜单
            MouseArea {
                anchors.fill: parent
                pressAndHoldInterval: 500
                // 长按弹出删除菜单并暂存好友信息
                onPressAndHold: {
                    deleteMenu.popup(mapToGlobal(width/2, height/2))
                    rootDelegate.currentFriendData = model
                }
            }

            // 好友项样式容器
            Rectangle{
                id: friendItemRect
                width: parent.width
                height: parent.height
                // 选中态与默认态颜色区分
                color: currentFriend && currentFriend.userId === model.userId ? "#cce5ff" : "lightgrey"
                radius: 8
                // 明确引用代理根ID，避免parent为null
                anchors.horizontalCenter: rootDelegate.horizontalCenter

                Column{
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // 好友名称按钮
                    Button{
                        id: btn
                        ButtonGroup.group: buttonGroup
                        width: 120
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        background:Rectangle{
                            anchors.fill: parent
                            border.color: "#666"
                            border.width: 1
                            radius: 20
                            color: btn.checked ? "#90ee90" : "#e6f7ff"
                        }
                        text: model.name
                        font.pixelSize: 14
                        font.bold: true
                        checkable: true
                        // 选中状态绑定当前好友
                        checked: currentFriend && currentFriend.userId === model.userId
                        // 点击触发好友选中信号
                        onClicked: friendSelected(model)
                    }

                    // 个性签名显示区域（悬浮提示完整内容）
                    MouseArea {
                        anchors.horizontalCenter: friendItemRect.horizontalCenter
                        width: friendItemRect.width * 0.9
                        height: friendItemRect.height - btn.height - 8
                        hoverEnabled: true

                        // 修复ToolTip重载歧义：用active属性自动绑定，无需手动show/hide
                        ToolTip {
                            text: model.content
                            delay: 200
                            // active: parent.containsMouse // 鼠标进入自动显示，离开自动隐藏
                        }

                        // 个性签名文本（最多显示2行）
                        Text {
                            text: model.content
                            anchors.fill: parent
                            font.pixelSize: 12
                            color: "#666"
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // 删除好友弹出菜单
            Popup {
                id: deleteMenu
                width: 120
                height: 40
                modal: false
                focus: true
                // 菜单居中弹出（基于好友项）
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2

                Menu {
                    MenuItem {
                        text: "删除好友"
                        font.pixelSize: 14
                        // color: "#f56c6c" // 警示色，与项目样式统一
                        // 点击触发删除好友信号
                        onClicked: {
                            friendDeleteRequested(rootDelegate.currentFriendData)
                                                       deleteMenu.close()
                        }
                    }
                }
            }
        }
    }
}
