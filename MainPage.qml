import QtQuick 2.15
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls.Fusion

Rectangle {
    id:mainpage
    color:"lightyellow"

    HotContent{
        anchors.top: mtop.bottom
        anchors.topMargin: 10
        height: parent.height-60-mtop.height
        width: parent.width
    }


    RowLayout{
        id:mtop
        anchors.top: parent.top
        width:parent.width/3
        height: 60
        Layout.alignment: Qt.AlignCenter
        Text {
            id: mtitle
            Layout.rightMargin: 10
            Layout.fillWidth: true
            font.pointSize: 18
            font.family: "Helvetica"
            font.bold: true
            style: Text.Outline
            styleColor: "green"
            color: "lightblue"
            text: "大象旅行"
        }
    }
}

