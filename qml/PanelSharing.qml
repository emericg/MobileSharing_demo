import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import MobileSharing

ColumnLayout {
    id: panelSharing

    width: 512
    spacing: 12

    // Share text & link ///////////////////////////////////////////////////////

    Card {
        title: "Share text & link"

        TextField {
            id: textField
            Layout.fillWidth: true
            placeholderText: "Text to share"
            text: "Hello from MobileSharing (demo)!"
        }
        TextField {
            id: urlField
            Layout.fillWidth: true
            placeholderText: "URL to share"
            text: "https://github.com/emericg/MobileSharing"
        }
        Button {
            Layout.fillWidth: true
            text: "Share text + URL"
            onClicked: MobileSharing.sendText(textField.text, "Shared from MobileSharing (demo)", urlField.text)
        }
    }

    // Receive / act on a file /////////////////////////////////////////////////

    Card {
        title: "Receive a file"

        ////

        Button {
            Layout.fillWidth: true
            text: "Open a file"
            onClicked: {
                // iOS: Qt's FileDialog returns an unreadable security-scoped URL, so use the
                // module's native import picker. Android/desktop: Qt's FileDialog works fine.
                if (Qt.platform.os === "ios") MobileSharing.openFile()
                else openFileDialog.open()
            }
        }

        ////

        Label {
            Layout.fillWidth: true
            visible: appWindow.lastFilePathReceived === ""
            text: "Nothing yet • share a file or image into this app • or open one"
            wrapMode: Text.Wrap
            font.pixelSize: 13
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            visible: appWindow.lastFilePathReceived !== ""
            text: appWindow.fileName(appWindow.lastFilePathReceived)
            elide: Text.ElideMiddle
            font.pixelSize: 12
            font.bold: true
            opacity: 0.8
        }

        ////

        Rectangle { // Preview box
            Layout.fillWidth: true
            Layout.preferredHeight: 240
            visible: appWindow.lastFilePathReceived !== ""
            radius: 6
            color: "#f6f6f6"
            border.color: "#cccccc"

            Image {
                anchors.fill: parent
                anchors.margins: 4
                visible: appWindow.isImage(appWindow.lastFilePathReceived)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                autoTransform: true
                source: appWindow.isImage(appWindow.lastFilePathReceived) ? "file://" + appWindow.lastFilePathReceived : ""
            }
            Label {
                anchors.centerIn: parent
                visible: appWindow.lastFilePathReceived !== "" && !appWindow.isImage(appWindow.lastFilePathReceived)
                text: "No preview\n(" + appWindow.guessMime(appWindow.lastFilePathReceived) + ")"
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.6
            }
        }

        ////

        Flow {
            Layout.fillWidth: true
            visible: appWindow.lastFilePathReceived !== ""
            spacing: 8

            Button {
                text: "Discard?"
                onClicked: {
                    MobileSharing.discardFileReceived(appWindow.lastFilePathReceived)
                    appWindow.lastFilePathReceived = ""
                    appWindow.scanStorage(0)
                }
            }

            Button {
                text: "Open with (Qt)"
                onClicked: Qt.openUrlExternally(appWindow.lastFilePathReceived)
            }
            Button {
                text: "View"
                onClicked: MobileSharing.viewFile(appWindow.lastFilePathReceived, appWindow.fileName(appWindow.lastFilePathReceived),
                                                  appWindow.guessMime(appWindow.lastFilePathReceived), 10)
            }
            Button {
                text: "Share"
                onClicked: MobileSharing.sendFile(appWindow.lastFilePathReceived, appWindow.fileName(appWindow.lastFilePathReceived),
                                                  appWindow.guessMime(appWindow.lastFilePathReceived), 11)
            }

            Button {
                visible: (Qt.platform.os === "android")

                text: "Copy to shared"
                onClicked: {
                    // Copy the received file into the SAF-exposed shared directory, then refresh its listing.
                    var dest = demoBackend.copyToDirectory(appWindow.lastFilePathReceived, MobileSharing.documentProvider.sharedDirectory)
                    if (dest) appWindow.scanStorage(1)
                    else console.warn("Copy to shared failed for " + appWindow.lastFilePathReceived)
                }
            }
        }

        ////
    }

    // Export / save a file ////////////////////////////////////////////////////

    Card {
        title: "Save a file"
        visible: lastFilePathReceived.length

        Label {
            Layout.fillWidth: true
            text: "Test whenever we can SAVE a file with Qt, or with MobileSharing saving code. We we'll save the last received file."
            wrapMode: Text.Wrap
            font.pixelSize: 12
            opacity: 0.6
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                Layout.fillWidth: true
                text: "Save via Qt"
                onClicked: {
                    appWindow.saveStatus = ""
                    appWindow.pendingSavePath = lastFilePathReceived
                    saveFileDialog.open()
                }
            }
            Button {
                Layout.fillWidth: true
                text: "Save via MobileSharing"
                onClicked: {
                    appWindow.saveStatus = ""
                    MobileSharing.saveFile(lastFilePathReceived, "sample.txt", "text/plain", appWindow.saveRequestCode)
                }
            }
        }
        Label {
            Layout.fillWidth: true
            visible: appWindow.saveStatus !== ""
            text: appWindow.saveStatus
            wrapMode: Text.Wrap
            font.pixelSize: 12
            opacity: 0.7
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
