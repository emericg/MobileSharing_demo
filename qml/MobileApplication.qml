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

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint
    visible: true
    color: "#eee"

    // MOBILE UI ///////////////////////////////////////////////////////////////

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

    MobileUI_dispatcher {
        statusbarColor: "#4361ee"

        navbarColor: "transparent"
        navbarContentColor: "#eee"
    }

    Item {
        id: systemBars
        anchors.fill: parent

        visible: true

        // System bars // Underlay backups
        Rectangle {
            id: statusbarUnderlay
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            visible: true
            height: MobileUI.statusbarHeight
            color: MobileUI.statusbarColor
        }
        Rectangle {
            id: navbarUnderlay
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            visible: true
            height: MobileUI.navbarHeight
            color: MobileUI.navbarContentColor
        }
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

    Component.onCompleted: {
        scanStorage(0)
        scanStorage(1)
    }

    onClosing: (close) => {
        if (Qt.platform.os === "android") {
            close.accepted = false
            MobileUI.backToHomeScreen()
        }
    }

    // MobileSharing ///////////////////////////////////////////////////////////

    readonly property int saveRequestCode: 20

    property string lastFilePathReceived: ""
    property string pendingSavePath: ""
    property string saveStatus: ""

    Connections {
        target: MobileSharing

        function onShareFinished(requestCode) {
            console.log("MobileSharing::onShareFinished(" + requestCode + ")")
        }
        function onShareNoAppAvailable(requestCode) {
            console.log("MobileSharing::onShareNoAppAvailable(" + requestCode + ")")
        }
        function onShareError(requestCode, message) {
            console.log("MobileSharing::onShareError(" + requestCode + ") " + message)
        }
        function onFileSaved(requestCode) {
            console.log("MobileSharing::onFileSaved(" + requestCode + ")")
        }

        function onFileReceived(path) {
            console.log("MobileSharing::onFileReceived(" + path + ")")
            appWindow.lastFilePathReceived = path
            appWindow.scanStorage(0)
        }
    }

    // C++ helper for the file I/O the QML layer can't do itself
    DemoBackend { id: demoBackend }

    // "Qt FileDialog" open route: (SAF on Android, UIDocumentPicker on iOS, native on desktop)
    // The chosen file is handed to the module, which copies it into our cache and emits
    // fileReceived() so a picked file flows through exactly the same path as a received share
    Platform.FileDialog {
        id: openFileDialog

        title: "Open a file"
        fileMode: Platform.FileDialog.OpenFile

        onAccepted: {
            console.log("openFileDialog::onAccepted(" + file + ")")
            MobileSharing.importFile(file)
        }
        onRejected: {
            console.log("openFileDialog::onRejected()")
        }
    }

    // "Qt FileDialog" save route: pick a destination, then try to write to it with QFile
    // On Android this returns a content:// URL that QFile can't write to - hence the native route
    Platform.FileDialog {
        id: saveFileDialog

        title: "Save file (Qt)"
        fileMode: Platform.FileDialog.SaveFile

        onAccepted: {
            console.log("saveFileDialog::onAccepted(" + file + ")")
            var ok = demoBackend.exportViaQFile(lastFilePathReceived, file)
            appWindow.saveStatus = ok ? "Qt FileDialog: saved OK" : "Qt FileDialog: FAILED (expected on Android)"
        }
        onRejected: {
            console.log("saveFileDialog::onRejected()")
            appWindow.saveStatus = "Qt FileDialog: canceled"
        }
    }

    // Helpers /////////////////////////////////////////////////////////////////

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
            case "heif": case "heic": return "image/heif"
            case "webp": return "image/webp"
            case "png": return "image/png"
            case "bmp": return "image/bmp"
            case "gif": return "image/gif"
            case "pdf": return "application/pdf"
            case "txt": return "text/plain"
            default: return "*/*"
        }
    }

    // Storage listing /////////////////////////////////////////////////////////

    // The module's session-wiped directories:
    // - Cache directory: 'cache/MobileSharing', with 'incoming/' and 'outgoing/' subdirs
    // - SAF DocumentsProvider persistent directory: 'files/shared/' by default
    readonly property url cacheRoot: Platform.StandardPaths.writableLocation(Platform.StandardPaths.CacheLocation) + "/MobileSharing"
    readonly property url sharedRoot: "file://" + MobileSharing.documentProvider.sharedDirectory

    // Flat list of every file (filled recursively by scanStorage())
    ListModel { id: storageFiles_cache }
    ListModel { id: storageFiles_shared }

    // Throwaway single-level model; we spawn one per directory we walk into
    Component {
        id: folderScanner
        FolderListModel {
            showDirs: true
            showDotAndDotDot: false
            showFiles: true
            nameFilters: ["*"]
            sortField: FolderListModel.Name
        }
    }

    // Pending directories left to visit: [{ url, rel }, ...]
    property var _scanQueue: []

    // Scan our cache/shared directories
    function scanStorage(selectedStorage) {
        var scanRootUrl

        if (selectedStorage === 0) {
            // cache
            scanRootUrl = cacheRoot
            storageFiles_cache.clear()
        } else {
            // shared
            scanRootUrl = sharedRoot
            storageFiles_shared.clear()
        }

        _scanQueue = [{ url: scanRootUrl, rel: "" }]
        _scanNext(selectedStorage)
    }

    function _scanNext(selectedStorage) {
        if (_scanQueue.length === 0) return
        var job = _scanQueue.shift()

        var m = folderScanner.createObject(appWindow, { folder: job.url })
        var consume = function() {
            for (var i = 0; i < m.count; i++) {
                var name = m.get(i, "fileName")
                //console.log("- " + name) // debug
                if (m.get(i, "fileIsDir")) {
                    _scanQueue.push({ url: m.get(i, "fileURL"), rel: job.rel + name + "/" })
                } else {
                    if (selectedStorage === 0) {
                        storageFiles_cache.append({ fName: name, fRel: job.rel + name,
                                                    fPath: m.get(i, "filePath"), fSize: m.get(i, "fileSize") })
                    } else {
                        storageFiles_shared.append({ fName: name, fRel: job.rel + name,
                                                     fPath: m.get(i, "filePath"), fSize: m.get(i, "fileSize") })
                    }
                }
            }
            m.destroy()
            _scanNext(selectedStorage)
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

    Item {
        id: appContent

        anchors.top: parent.top
        //anchors.topMargin: Math.max(appWindow.screenPaddingStatusbar, appWindow.screenPaddingTop)
        anchors.left: parent.left
        anchors.leftMargin: screenPaddingLeft
        anchors.right: parent.right
        anchors.rightMargin: screenPaddingRight
        anchors.bottom: parent.bottom
        //anchors.bottomMargin: Math.max(appWindow.screenPaddingNavbar, appWindow.screenPaddingBottom)

        Keys.onBackPressed: {
            MobileUI.backToHomeScreen()
        }

        // Landscape: panels side by side (2 columns)
        // Portrait: panels stacked (2 rows)
        property bool isWide: width > height

        ScrollView {
            anchors.fill: parent

            topPadding: Math.max(appWindow.screenPaddingStatusbar, appWindow.screenPaddingTop)
            bottomPadding: Math.max(appWindow.screenPaddingNavbar, appWindow.screenPaddingBottom)

            Flickable {
                contentWidth: -1
                contentHeight: contentColumn.height

                ColumnLayout {
                    id: contentColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    spacing: 12

                    Row { // Header ////////////////////////////////////////////
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        spacing: 8

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 4

                            text: "MobileSharing"
                            font.pixelSize: 24
                            font.bold: true

                            Label {
                                anchors.top: parent.top
                                anchors.topMargin: -4
                                anchors.left: parent.right
                                anchors.leftMargin: 4

                                text: "demo"
                                font.pixelSize: 16
                                font.bold: true
                                opacity: 0.6
                            }
                        }
                    }

                    GridLayout { // Responsive grid ////////////////////////////
                        Layout.fillWidth: true

                        columns: appContent.isWide ? 2 : 1
                    columnSpacing: 12
                    rowSpacing: 12

                    ////

                    PanelSharing {
                        id: panelSharing

                        Layout.fillWidth: true
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignTop
                    }

                    ////

                    PanelStorage {
                        id: panelStorage

                        Layout.fillWidth: true
                        Layout.preferredWidth: 100
                        Layout.alignment: Qt.AlignTop
                    }

                    ////
                    }
                }

                ////////////////////////////////////////////////////////////////
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
}
