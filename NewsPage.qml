import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import ProjectExp

Item{
    width: parent.width
    height: parent.height
    property int bottomMargin: 0
    id: root // 根Item

    // ========== 数据模型 ==========
    ListModel { id: friendsModel }
    ListModel { id: chatRecordsModel }
    property var currentFriend: null // 根Item的属性
    property int pendingDeleteFriendId: -1 // 暂存要删除的好友ID

    // ========== 初始化+信号绑定（添加+删除好友信号全绑定） ==========
    Component.onCompleted: {
        SqlApi.friendsLoaded.connect(updateFriendsModel)
        SqlApi.chatRecordsLoaded.connect(updateChatRecords)
        SqlApi.messageSent.connect(onMessageSent)
        SqlApi.friendAdded.connect(onFriendAdded) // 绑定添加好友结果
        SqlApi.friendDeleted.connect(onFriendDeleted) // 绑定删除好友结果
        SqlApi.getMyFriends()
    }

    onVisibleChanged: {
        if (visible) Qt.callLater(SqlApi.getMyFriends)
    }

    // ========== 核心：监听currentFriend变化（原有逻辑，保留不变） ==========
    onCurrentFriendChanged: {
        if (currentFriend) {
            // 1. 加载聊天面板
            chatLoader.source = "chatPanel.qml"
            // 2. 加载聊天记录
            SqlApi.getChatRecords(currentFriend.userId)
            // 3. 给聊天面板传递参数
            Qt.callLater(function() {
                if (chatLoader.item) {
                    chatLoader.item.friendInfo = currentFriend
                    chatLoader.item.chatRecordsModel = chatRecordsModel
                    chatLoader.item.sendMessageFunc = sendChatMessage
                    chatLoader.item.onFriendDeleteRequested.connect(handleFriendDelete)
                }
            })
        }
    }

    // ========== 新增：添加好友结果处理 ==========
    function onFriendAdded(success, tip) {
        tipDialog.contentItem.text = tip
        tipDialog.open()
        // 添加成功后清空输入框
        if (success) {
            friendNicknameInput.text = ""
        }
    }

    // ========== 新增：删除好友结果处理 ==========
    function onFriendDeleted(success, tip) {
        tipDialog.contentItem.text = tip
        tipDialog.open()
        // 删除成功后，清空选中的已删除好友
        if (success && currentFriend) {
            let friendExist = false
            for (let i = 0; i < friendsModel.count; i++) {
                if (friendsModel.get(i).userId === currentFriend.userId) {
                    friendExist = true
                    break
                }
            }
            if (!friendExist) {
                currentFriend = friendsModel.count > 0 ? friendsModel.get(0) : null
            }
        }
        pendingDeleteFriendId = -1
    }

    // ========== 新增：统一处理删除好友请求 ==========
    function handleFriendDelete(friendInfo) {
        if (friendInfo) {
            pendingDeleteFriendId = friendInfo.userId
            confirmDeleteDlg.open() // 弹出二次确认框
        }
    }

    // ========== 模型更新函数（原有逻辑，保留不变） ==========
    function updateFriendsModel(friends) {
        Qt.callLater(function() {
            friendsModel.clear()
            friends.forEach(friend => friendsModel.append(friend))
            if (friendsModel.count > 0 && !currentFriend) {
                currentFriend = friendsModel.get(0)
            }
        })
    }

    function updateChatRecords(records) {
        Qt.callLater(function() {
            chatRecordsModel.clear()
            records.forEach(record => chatRecordsModel.append(record))
            if (chatLoader.item) {
                chatLoader.item.chatRecordsModel = chatRecordsModel
            }
        })
    }

    function onMessageSent(success) {
        if (!success) console.log("消息发送失败！")
    }

    function sendChatMessage(content) {
        if (currentFriend && content.trim()) {
            SqlApi.sendMessage(currentFriend.userId, content.trim())
        }
    }

    // ========== 页面布局（核心：修复rightOf错误，明确锚点绑定） ==========
    Item {
        id: rootContent
        anchors.fill: parent
        anchors.bottomMargin: root.bottomMargin

        // 左侧：添加好友按钮 + 好友列表（给Column加id：friendListContainer，便于锚定）
        Column {
            id: friendListContainer // 新增id，用于右侧聊天面板锚定
            width: parent.width/3
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 20
            spacing: 15 // 按钮与列表间距，样式统一

            // 全新：添加好友按钮（蓝色主题，与项目样式一致）
            Button {
                text: "添加好友"
                width: parent.width * 0.9
                height: 40
                anchors.horizontalCenter: parent.horizontalCenter
                background: Rectangle {
                    color: "#409eff"
                    radius: 8
                }
                palette.buttonText: "white"
                font.pixelSize: 14
                font.bold: true
                onClicked: addFriendDlg.open() // 点击弹出添加对话框
            }

            // 原有：好友列表组件（绑定删除信号）
            FriendListView {
                id: friendList
                width: parent.width
                height: parent.height - 40 - 15 // 减去按钮高度和间距
                friendsModel: friendsModel
                currentFriend: root.currentFriend
                onFriendSelected: function(friend) {
                    root.currentFriend = friend
                }
                onFriendDeleteRequested: function(friendInfo) {
                    root.handleFriendDelete(friendInfo)
                }
            }
        }

        // 右侧：聊天面板Loader（修复锚点错误，替换rightOf函数调用）
        Loader{
            id:chatLoader
            width: parent.width - (parent.width/3) - 40
            height: parent.height
            // 核心修复：正确锚点绑定，无函数调用
            anchors.left: friendListContainer.right // 锚定到好友列表容器的右侧
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            onLoaded: {
                item.friendInfo = root.currentFriend
                item.chatRecordsModel = root.chatRecordsModel
                item.sendMessageFunc = root.sendChatMessage
                item.onFriendDeleteRequested.connect(root.handleFriendDelete)
            }
        }
    }

    // ========== 全新：添加好友对话框 ==========
    Dialog {
        id: addFriendDlg
        title: "添加好友"
        width: 350
        height: 270
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                text: "好友昵称"
                font.pixelSize: 14
                color: "#333"
            }

            TextField {
                id: friendNicknameInput
                Layout.fillWidth: true
                placeholderText: "输入好友昵称"
                font.pixelSize: 14
                background: Rectangle {
                    color: "#f5f5f5"
                    border.color: "#ddd"
                    radius: 6
                }
            }
        }

        // 确认添加
        onAccepted: {
            if (friendNicknameInput.text.trim()) {
                SqlApi.addFriend(friendNicknameInput.text.trim())
            }
        }

        // 取消添加，清空输入框
        onRejected: {
            friendNicknameInput.text = ""
        }
    }

    // ========== 全新：删除好友确认对话框 ==========
    Dialog {
        id: confirmDeleteDlg
        title: "确认删除"
        width: 300
        height: 150
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: Text {
            text: "确定要删除该好友吗？删除后无法恢复！"
            font.pixelSize: 14
            color: "#333"
            anchors.centerIn: parent
            wrapMode: Text.Wrap
        }

        onAccepted: {
            if (pendingDeleteFriendId !== -1) {
                SqlApi.deleteFriend(pendingDeleteFriendId)
            }
        }

        onRejected: {
            pendingDeleteFriendId = -1
        }
    }

    // ========== 全新：通用提示对话框（替换MessageDialog，兼容所有版本） ==========
    Dialog {
        id: tipDialog
        title: "提示"
        width: 300
        height: 150
        modal: true
        standardButtons: Dialog.Ok

        contentItem: Text {
            text: ""
            font.pixelSize: 14
            anchors.centerIn: parent
            wrapMode: Text.Wrap
        }
    }
}
