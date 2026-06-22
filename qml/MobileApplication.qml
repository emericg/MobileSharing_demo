import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Qt.labs.folderlistmodel
import Qt.labs.platform as Platform

import MobileUI
import MobileSharing

Window {
    id: appWindow

    minimumWidth: 480
    minimumHeight: 960

    visible: true
    color: "#eeeeee"

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    property bool isDesktop: (Qt.platform.os !== "ios" && Qt.platform.os !== "android")
    property bool isMobile: (Qt.platform.os === "ios" || Qt.platform.os === "android")
    property bool isPhone: MobileUI.isPhone
    property bool isTablet: MobileUI.isTablet

    // Mobile stuff ////////////////////////////////////////////////////////////

    // 1 = Qt.PortraitOrientation, 2 = Qt.LandscapeOrientation
    // 4 = Qt.InvertedPortraitOrientation, 8 = Qt.InvertedLandscapeOrientation
    property int screenOrientation: Screen.primaryOrientation
    property int screenOrientationFull: Screen.orientation

    property int screenPaddingStatusbar: MobileUI.statusbarHeight
    property int screenPaddingNavbar: MobileUI.navbarHeight

    property int screenPaddingTop: MobileUI.safeAreaTop
    property int screenPaddingLeft: MobileUI.safeAreaLeft
    property int screenPaddingRight: MobileUI.safeAreaRight
    property int screenPaddingBottom: MobileUI.safeAreaBottom

    Component.onCompleted: {
        MobileUI.statusbarColor = "#4361ee"
        MobileUI.statusbarTheme = MobileUI.Dark

        MobileUI.navbarColor = "#eeeeee"
        MobileUI.navbarTheme = MobileUI.Light

        scanCache()
    }

    // Events handling /////////////////////////////////////////////////////////

    Connections {
        target: Qt.application
        function onStateChanged() {
            switch (Qt.application.state) {
                case Qt.ApplicationSuspended:
                    //console.log("Qt.ApplicationSuspended")
                    break
                case Qt.ApplicationHidden:
                    //console.log("Qt.ApplicationHidden")
                    break
                case Qt.ApplicationInactive:
                    //console.log("Qt.ApplicationInactive")
                    break
                case Qt.ApplicationActive:
                    //console.log("Qt.ApplicationActive")
                    break
            }
        }
    }

    // MobileSharing ///////////////////////////////////////////////////////////

    property string lastFilePathReceived: ""

    MobileSharing {
        id: mobileSharing

        onShareFinished: (requestCode) => {
            console.log("MobileSharing::onShareFinished(" + requestCode + ")")
        }
        onShareNoAppAvailable: (requestCode) => {
            console.log("MobileSharing::onShareNoAppAvailable(" + requestCode + ")")
        }
        onShareError: (requestCode, message) => {
            console.log("MobileSharing::onShareError(" + requestCode + ") " + message)
        }

        onFileReceived: (path) => {
            console.log("MobileSharing::onFileReceived(" + path + ")")
            appWindow.lastFilePathReceived = path
            appWindow.scanCache()
        }
    }

    // Qt's native file picker (SAF on Android, UIDocumentPicker on iOS, native on desktop).
    // The chosen file is handed to the module, which copies it into our cache and emits
    // fileReceived() - so a picked file flows through exactly the same path as a received share.
    Platform.FileDialog {
        id: openFileDialog

        title: "Open a file"
        fileMode: Platform.FileDialog.OpenFile

        onAccepted: {
            console.log("FileDialog::onAccepted(" + file + ")")
            mobileSharing.importFile(file)
        }
    }

    // Helpers ///////////////////////////////////////////////////////////////////

    function fileName(p) {
        return p ? p.substring(p.lastIndexOf('/') + 1) : ""
    }
    function fileExt(p) {
        var n = fileName(p)
        var i = n.lastIndexOf('.')
        return (i >= 0) ? n.substring(i + 1).toLowerCase() : ""
    }
    function isImage(p) {
        return ["jpg", "jpeg", "png", "gif", "webp", "bmp"].indexOf(fileExt(p)) >= 0
    }
    function isText(p) {
        return ["txt", "rtf", "md", "csv"].indexOf(fileExt(p)) >= 0
    }
    function guessMime(p) {
        switch (fileExt(p)) {
            case "jpg": case "jpeg": return "image/jpeg"
            case "png": return "image/png"
            case "gif": return "image/gif"
            case "webp": return "image/webp"
            case "bmp": return "image/bmp"
            case "pdf": return "application/pdf"
            case "txt": return "text/plain"
            default: return "*/*"
        }
    }

    // Cache listing /////////////////////////////////////////////////////////////

    // The module's cache directory ('cache/MobileSharing/' with 'incoming/' and 'outgoing/' subdirectories)
    readonly property url cacheRoot: Platform.StandardPaths.writableLocation(Platform.StandardPaths.CacheLocation) + "/MobileSharing"

    // Flat list of every file found below cacheRoot (filled recursively by scanCache()).
    ListModel { id: cacheFiles }

    // Throwaway single-level model; we spawn one per directory we walk into.
    Component {
        id: folderScanner
        FolderListModel {
            showDirs: true
            showDotAndDotDot: false
            showFiles: true
            nameFilters: ["*"]   // every file, including extension-less ones
            sortField: FolderListModel.Name
        }
    }

    // Pending directories left to visit: [{ url, rel }, ...]
    property var _scanQueue: []

    // Walk cacheRoot depth-first and (re)populate cacheFiles with relative paths.
    function scanCache() {
        cacheFiles.clear()
        _scanQueue = [{ url: cacheRoot, rel: "" }]
        _scanNext()
    }

    function _scanNext() {
        if (_scanQueue.length === 0) return
        var job = _scanQueue.shift()

        var m = folderScanner.createObject(appWindow, { folder: job.url })
        var consume = function() {
            for (var i = 0; i < m.count; i++) {
                var name = m.get(i, "fileName")
                if (m.get(i, "fileIsDir")) {
                    _scanQueue.push({ url: m.get(i, "fileURL"), rel: job.rel + name + "/" })
                } else {
                    cacheFiles.append({ fName: name,
                                        fRel: job.rel + name,
                                        fPath: m.get(i, "filePath"),
                                        fSize: m.get(i, "fileSize") })
                }
            }
            m.destroy()
            _scanNext()
        }

        if (m.status === FolderListModel.Ready) {
            consume()
        } else {
            var onStatus = function() {
                if (m.status === FolderListModel.Ready) {
                    m.statusChanged.disconnect(onStatus)
                    consume()
                }
            }
            m.statusChanged.connect(onStatus)
        }
    }

    // UI //////////////////////////////////////////////////////////////////////

    FocusScope {
        id: appContent

        anchors.top: parent.top
        anchors.topMargin: Math.max(appWindow.screenPaddingStatusbar, appWindow.screenPaddingTop)
        anchors.left: parent.left
        anchors.leftMargin: screenPaddingLeft
        anchors.right: parent.right
        anchors.rightMargin: screenPaddingRight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(appWindow.screenPaddingNavbar, appWindow.screenPaddingBottom)

        focus: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Title ///////////////////////////////////////////////////////////

            Row {
                Layout.fillWidth: true

                Label {
                    text: "MobileSharing"
                    font.pixelSize: 28
                    font.bold: true
                }
                Label {
                    text: "demo"
                    opacity: 0.6
                }
            }

            // Send text/URL ///////////////////////////////////////////////////

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
                onClicked: {
                    mobileSharing.sendText(textField.text, "Shared from MobileSharing (demo)", urlField.text)
                }
            }
            Button {
                Layout.fillWidth: true

                text: "Open file"
                onClicked: openFileDialog.open()
            }

            // Received file ///////////////////////////////////////////////////

            RowLayout {
                height: 32
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Label {
                    Layout.fillWidth: true

                    text: "File received"
                    font.bold: true
                    font.pixelSize: 18
                }
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
/*
            Label {
                Layout.fillWidth: true

                visible: appWindow.lastFilePathReceived !== ""
                text: appWindow.lastFilePathReceived
                wrapMode: Text.WrapAnywhere
                font.pixelSize: 10
                opacity: 0.5
            }
*/
            Label {
                Layout.fillWidth: true

                visible: appWindow.lastFilePathReceived === ""
                text: "Nothing yet — share a file or image into this app."
                wrapMode: Text.Wrap
                opacity: 0.6
            }

            Rectangle { // Preview box
                Layout.fillWidth: true
                Layout.preferredHeight: 240

                visible: appWindow.lastFilePathReceived !== ""
                radius: 6
                color: "#ffffff"
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

            RowLayout { // Buttons row
                Layout.fillWidth: true

                visible: appWindow.lastFilePathReceived !== ""
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    text: "Open with"
                    onClicked: {
                        mobileSharing.viewFile(appWindow.lastFilePathReceived, appWindow.fileName(appWindow.lastFilePathReceived),
                                               appWindow.guessMime(appWindow.lastFilePathReceived), 10)
                    }
                }
                Button {
                    Layout.fillWidth: true
                    text: "Share"
                    onClicked: {
                        mobileSharing.sendFile(appWindow.lastFilePathReceived, appWindow.fileName(appWindow.lastFilePathReceived),
                                               appWindow.guessMime(appWindow.lastFilePathReceived), 11)
                    }
                }
                Button {
                    Layout.fillWidth: true
                    text: "Discard"
                    onClicked: {
                        mobileSharing.discardFileReceived(appWindow.lastFilePathReceived)
                        appWindow.lastFilePathReceived = ""
                        appWindow.scanCache()
                    }
                }
            }

            // Received file(s) ////////////////////////////////////////////////

            RowLayout {
                height: 32
                Layout.fillWidth: true

                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    text: "Cached contents (" + cacheFiles.count + ")"
                    font.pixelSize: 18
                    font.bold: true
                }
                Button {
                    Layout.alignment: Qt.AlignVCenter

                    text: "Refresh"
                    onClicked: appWindow.scanCache()
                }
            }

            ListView {
                id: cacheFolderViewer
                Layout.fillWidth: true
                Layout.preferredHeight: 256
                clip: true

                model: cacheFiles

                Label {
                    anchors.centerIn: parent
                    visible: cacheFiles.count === 0
                    text: "Cache is empty..."
                    opacity: 0.5
                }

                delegate: Item {
                    width: ListView.view.width
                    height: 28

                    required property string fRel
                    required property int fSize

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4
                        spacing: 8

                        Label {
                            Layout.fillWidth: true

                            text: "<cache>/MobileSharing/" + fRel
                            elide: Text.ElideMiddle
                            font.pixelSize: 12
                            opacity: 0.5
                        }
                        Label {
                            text: (fSize / 1024).toFixed(0) + " kB"
                            opacity: 0.5
                        }
                    }
                }
            }

            ////////////////////////////////////////////////////////////////////
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
