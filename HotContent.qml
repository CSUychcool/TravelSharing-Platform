import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ProjectExp

Item {
    width: parent.width
    height: parent.height

    // 攻略数据模型（从SQL加载）
    ListModel {
        id: hotStrategyModel
    }

    // 初始化：从SQL获取“最火攻略”
    Component.onCompleted: {
         console.log("QML收到攻略总数")
        // 调用C++后端接口（需确保SqlApi已注册对应方法）
        SqlApi.onHotStrategiesLoaded.connect((strategies) => {
            hotStrategyModel.clear()
            console.log("QML收到攻略总数：", strategies.length) // 先确认收到列表
            strategies.forEach(strategy => {
                hotStrategyModel.append({
                    id: strategy.id,
                    city: strategy.city,
                    content: strategy.content,
                    heat: strategy.heat // 热度值，用于显示“热门”标签
                })
            })
        })
         SqlApi.getHotStrategies()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 标题栏
        Text {
            text: "最火旅游攻略推送"
            font.pixelSize: 28
            font.bold: true
            color: "#333"
            Layout.alignment: Qt.AlignHCenter
        }

        // 攻略列表
        ListView {
            id: strategyList
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15
            model: hotStrategyModel
            clip: true

            delegate: Rectangle {
                width: strategyList.width
                height: 120
                color: "#ffe6e6" // 粉色系（和你现有风格统一）
                radius: 8
                border.color: "#ffcccc"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    // 城市+热度标签
                    RowLayout {
                        Text {
                            text: model.city
                            font.pixelSize: 20
                            font.bold: true
                            color: "#d81e06"
                        }
                        Rectangle {
                            width: 40
                            height: 20
                            color: "#ff4d4d"
                            radius: 3
                            Text {
                                text: "热门"
                                font.pixelSize: 12
                                color: "white"
                                anchors.centerIn: parent
                            }
                            visible: model.heat > 100 // 热度阈值控制显示
                        }
                    }

                    // 攻略内容
                    Text {
                        text: model.content
                        font.pixelSize: 14
                        color: "#666"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
