import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    signal friendDeleteRequested(var friendInfo) // 新增：删除好友请求信号
    property var friendInfo: null
    property ListModel chatRecordsModel: null
    property var sendMessageFunc: null
    anchors.fill: parent

    // 聊天框主容器（原有逻辑，保留不变）
    Rectangle{
        anchors.fill: parent
        anchors.margins: 10
        radius: 8
        border.color: "#ddd"
        border.width: 1
        color: "white"

        ColumnLayout{
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10

            // 修改：聊天标题 + 删除好友按钮（横向布局）
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 10

                Text{
                    text: friendInfo ? "与「" + friendInfo.name + "」的聊天" : "未选择好友"
                    font.bold: true
                    font.pixelSize: 18
                    color: "#333"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                }

                // 全新：删除好友按钮（仅选中好友时显示）
                Button {
                    visible: friendInfo !== null
                    text: "删除好友"
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 30
                    font.pixelSize: 12
                    background: Rectangle {
                        color: "#f56c6c"
                        radius: 6
                    }
                    palette.buttonText: "white"
                    onClicked: {
                        friendDeleteRequested(friendInfo) // 触发删除信号
                    }
                }
            }

            // 消息区（原有逻辑，完全不变）
            ScrollView{
                Layout.fillWidth: true
                Layout.preferredHeight: parent.height * 0.6
                background: Rectangle{color: "#f9f9f9"; radius: 6}

                Column{
                    width: parent.width
                    spacing: 10
                    anchors.margins: 10

                    Repeater{
                        model: chatRecordsModel
                        delegate: Rectangle{
                            width: 360
                            height: contentText.height + 20
                            radius: 15
                            color: model.isSelf ? "#e6f7ff" : "#f5f5f5"
                            anchors.right: model.isSelf ? parent.right : undefined
                            anchors.left: model.isSelf ? undefined : parent.left

                            Text{
                                id: contentText
                                text: model.content
                                width: 340
                                font.pixelSize: 14
                                color: "#333"
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignTop
                            }
                        }
                    }
                }
            }

            // 分割线 + 输入区（原有逻辑，完全不变）
            Rectangle{
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#ddd"
            }

            RowLayout{
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                spacing: 10

                TextField{
                    id: msgInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: "输入消息..."
                    font.pixelSize: 14
                    padding: 15
                    wrapMode: TextEdit.Wrap
                    verticalAlignment: TextEdit.AlignTop
                    background: Rectangle{color: "#f5f5f5"; border.color: "#ddd"; border.width: 1; radius: 8}
                }

                Button{
                    text: "发送"
                    Layout.preferredWidth: 80
                    Layout.fillHeight: true
                    background: Rectangle{color: "#409eff"; radius: 8}
                    font.pixelSize: 14
                    onClicked: {
                        if (sendMessageFunc && msgInput.text.trim()) {
                            sendMessageFunc(msgInput.text.trim())
                            msgInput.text = ""
                        }
                    }
                }
            }
        }
    }
}
