import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: card

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight + 24

    radius: 0
    color: "#fff"
    border.color: "#eee"

    property string title: ""
    default property alias content: cardContent.data

    ColumnLayout {
        id: cardColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        Label {
            Layout.fillWidth: true
            visible: card.title.length > 0
            text: card.title
            font.bold: true
            font.pixelSize: 16
        }
        ColumnLayout {
            id: cardContent
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
