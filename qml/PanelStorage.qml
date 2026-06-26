import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Qt.labs.folderlistmodel

import MobileSharing

ColumnLayout {
    id: panelStorage

    width: 512
    spacing: 12

    // Share a folder (SAF DocumentsProvider) //////////////////////////////////

    Card {
        title: "Share a folder"
        visible: (Qt.platform.os === "android")

        ////

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: "Expose a folder to other apps"
                wrapMode: Text.Wrap
            }
            Switch {
                checked: MobileSharing.documentProvider.enabled
                onToggled: MobileSharing.documentProvider.enabled = checked
            }
        }
        Label {
            Layout.fillWidth: true
            text: "Read-only • appears in the system file picker (Android)"
            wrapMode: Text.Wrap
            font.pixelSize: 13
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            text: MobileSharing.documentProvider.sharedDirectory
            wrapMode: Text.WrapAnywhere
            font.pixelSize: 11
            opacity: 0.5
        }

        ////
    }

    // Storage inspector ///////////////////////////////////////////////////////

    Card {
        title: "Storage"

        ////

        TabBar {
            id: storageTabs

            Layout.fillWidth: true
            visible: (Qt.platform.os === "android")

            property int storageCount: storageTabs.currentIndex ? storageFiles_shared.count
                                                                : storageFiles_cache.count

            currentIndex: 0
            onCurrentIndexChanged: {
                //appWindow.scanStorage(storageTabs.currentIndex)
            }

            TabButton { text: "Cache" }
            TabButton { text: "Shared folder" }
        }

        ////

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                Layout.fillWidth: true
                text: storageTabs.storageCount + " file(s)"
                font.pixelSize: 12
                opacity: 0.6
            }
            Button {
                text: "Refresh"
                onClicked: appWindow.scanStorage(storageTabs.currentIndex)
            }
        }

        Label {
            Layout.fillWidth: true
            visible: storageTabs.storageCount === 0
            text: (storageTabs.currentIndex === 1) ? "Shared folder is empty..."
                                                   : "Cache is empty..."
            opacity: 0.5
            font.pixelSize: 12
        }

        ////

        Repeater {
            model: (storageTabs.currentIndex ? storageFiles_shared : storageFiles_cache)
            //model: storageFiles_cache

            delegate: RowLayout {
                required property string fRel
                required property int fSize

                Layout.fillWidth: true
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: fRel
                    elide: Text.ElideMiddle
                    font.pixelSize: 12
                    opacity: 0.6
                }
                Label {
                    text: (fSize / 1024).toFixed(0) + " kB"
                    font.pixelSize: 12
                    opacity: 0.5
                }
            }
        }

        ////
    }

    ////////////////////////////////////////////////////////////////////////////
}
