import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import ProjectExp

Item {
    width: parent.width
    height: parent.height

    // 攻略数据模型（从SQL加载）
    ListModel {
        id: strategyModel
    }

    // 新增：城市动态模型（替代固定数组）
       ListModel {
           id: cityModel
       }


    // 筛选条件
    property string filterCity: "全部"
    property string filterCategory: "全部"

    // 初始化：加载全部攻略
    Component.onCompleted:
    {
       loadCities() // 先加载城市
      // loadStrategies()
    }

    function loadCities(){
        // 连接城市加载完成信号
              SqlApi.onCitiesLoaded.connect((cityList) => {
                  cityModel.clear()
                  // 第一步：先添加“全部”选项（保持筛选逻辑一致）
                  cityModel.append({cityName: "全部"})
                  // 第二步：添加数据库拉取的城市列表
                  cityList.forEach(city => {
                      cityModel.append({cityName: city})
                  })
                  // 城市加载完成后，再加载攻略
                  loadStrategies()
              })
              // 调用C++接口获取城市
              SqlApi.getAllCities()
    }

    // 从SQL加载攻略（支持筛选：修正信号连接顺序 + 补充热度字段）
    function loadStrategies() {
        // 先断开旧信号连接，避免重复回调
       // SqlApi.onStrategiesLoaded.disconnect()

        // 1. 先连接信号（关键：顺序调整）
        SqlApi.onStrategiesLoaded.connect((strategies) => {
            strategyModel.clear()
            console.log("QML收到攻略总数：", strategies.length)
            strategies.forEach(strategy => {
                // 补充 heat 字段（接收C++传递的热度数据）
                strategyModel.append({
                    id: strategy.id,
                    city: strategy.city,
                    content: strategy.content,
                    category: strategy.category,
                    heat: strategy.heat, // 新增：热度字段（与C++对应）
                    hotScore: strategy.hotScore, // 兼容：可选，二选一即可
                    isCollected: strategy.isCollected
                })
            })
        })

        // 2. 后调用C++接口（关键：顺序调整）
        SqlApi.filterStrategies(filterCity, filterCategory)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 筛选+发布栏
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            // 城市筛选
            ComboBox {
                id: cityCombo
                model: cityModel
                textRole: "cityName"
                currentIndex: 0
                onCurrentTextChanged: {
                    filterCity = currentText
                    loadStrategies()
                }
                Layout.preferredWidth: 120
            }

            // 分类筛选
            ComboBox {
                id: categoryCombo
                model: ["全部", "自然风景", "人文景点", "美食推荐"]
                currentIndex: 0
                onCurrentTextChanged: {
                    filterCategory = currentText
                    loadStrategies()
                }
                Layout.preferredWidth: 120
            }

            // 发布攻略按钮
            Button {
                text: "发布我的攻略"
                background: Rectangle {
                    color: "#409eff"
                    radius: 6
                }
                palette.buttonText: "white"
                onClicked: publishDialog.open()
                Layout.alignment: Qt.AlignRight
            }
        }

        // 攻略列表
        ListView {
            id: strategyListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15
            model: strategyModel
            clip: true

            delegate: Rectangle {
                width: strategyListView.width // 优化：替代 strategyListView.width，更通用
                height: 150 // 增加高度，容纳热度显示
                color: "#ffe6e6"
                radius: 8
                border.color: "#ffcccc"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    // 城市+分类
                    RowLayout {
                        Text {
                            text: model.city
                            font.pixelSize: 20
                            font.bold: true
                            color: "#d81e06"
                        }
                        Text {
                            text: "[" + model.category + "]"
                            font.pixelSize: 14
                            color: "#999"
                            Layout.leftMargin: 10
                        }
                    }

                    // 攻略内容
                    Text {
                        text: model.content
                        font.pixelSize: 14
                        color: "#666"
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                        maximumLineCount: 2 // 限制行数，避免内容过长
                        elide: Text.ElideRight
                    }

                    // 热度 + 收藏按钮（新增热度显示）
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: 15 // 间距，避免控件重叠

                        // 热度显示（新增：核心修复热度不显示问题）
                        RowLayout {
                            // 可选：添加热度图标（更直观）
                            Text {
                                text: "热度："
                                font.pixelSize: 12
                                color: "#666"
                            }
                            Text {
                                text: model.heat // 绑定模型的热度字段
                                font.pixelSize: 12
                                font.bold: true
                                color: "#ff4d4d"
                            }
                        }

                        // 收藏按钮（修正：确保currentUser有效）
                        Button {
                            text: model.isCollected ? "已收藏" : "收藏"
                            background: Rectangle {
                                color: model.isCollected ? "#999" : "#ff4d4d"
                                radius: 4
                            }
                            palette.buttonText: "white"
                            onClicked: {
                                // 确认root.currentUser能获取当前登录用户，否则替换为SqlApi.currentUser
                                let currentUser = root.currentUser || SqlApi.currentUser
                                if (currentUser === "") {
                                    console.log("收藏失败：未登录")
                                    return
                                }
                                SqlApi.collectStrategy(model.id, currentUser)
                                model.isCollected = !model.isCollected // 本地刷新状态
                            }
                        }
                    }
                }
            }
        }
    }

    // 发布攻略对话框（修正：新增标题输入 + 修正传参顺序）
    // 发布攻略对话框（完整模块：保留所有原有逻辑 + 修复布局/焦点问题）
    Dialog {
        id: publishDialog
        title: "发布旅游攻略"
        width: 400
        height: 500 // 核心修复：增大高度，容纳所有填写栏（原350）
        standardButtons: Dialog.Ok | Dialog.Cancel

        // 新增：Dialog打开时自动聚焦标题输入框（确保可直接输入）
        onOpened: {
            publishTitle.focus = true;
        }

        // 原有完整的确认发布逻辑（未做任何删减，完整保留）
        onAccepted: {
            // 先校验是否登录（用户ID是否为0）
            if (SqlApi.currentUserId === 0) {
                console.log("发布失败：请先登录");
                return;
            }
            // 校验输入非空
            if (publishTitle.text.trim() === "" || publishCity.text.trim() === "" || publishContent.text.trim() === "") {
                console.log("发布失败：标题/城市/内容不能为空");
                return;
            }
            // 传入整数类型的 currentUserId
            SqlApi.publishStrategy(
                SqlApi.currentUserId, // 不再传用户名，传用户ID（整数）
                publishTitle.text,
                publishCity.text,
                publishContent.text,
                publishCategory.currentText
            );
            loadStrategies();
        }

        // 原有完整布局（ColumnLayout + 所有填写控件，仅调整Dialog高度）
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15 // 原有间距，未修改

            // 攻略标题（原有控件，完整保留）
            Text { text: "攻略标题："; font.pixelSize: 14 }
            TextField {
                id: publishTitle
                placeholderText: "输入攻略标题（如：桂林3日游全攻略）"
                Layout.fillWidth: true
            }

            // 城市（原有控件，完整保留）
            Text { text: "城市："; font.pixelSize: 14 }
            TextField {
                id: publishCity
                placeholderText: "输入城市"
                Layout.fillWidth: true
            }

            // 分类（原有控件，完整保留）
            Text { text: "分类："; font.pixelSize: 14 }
            ComboBox {
                id: publishCategory
                model: ["自然风景", "人文景点", "美食推荐"]
                Layout.fillWidth: true
            }

            // 攻略内容（原有控件，完整保留，仅保留你的注释状态）
            Text { text: "攻略内容："; font.pixelSize: 14 }
            TextArea {
                id: publishContent
                placeholderText: "分享你的旅游体验..."
                Layout.fillHeight: true // 原有布局属性，未修改
                Layout.fillWidth: true // 原有布局属性，未修改
                wrapMode: TextArea.Wrap // 原有优化属性，未修改
                //minimumHeight: 150 // 你的原有注释状态，完整保留
            }
        }
    }
}
