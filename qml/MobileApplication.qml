import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import Qt.labs.folderlistmodel

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

    MobileSharing {
        id: mobileSharing

        onShareFinished: (requestCode) => appLog.add("shareFinished (" + requestCode + ")")
        onShareNoAppAvailable: (requestCode) => appLog.add("shareNoAppAvailable (" + requestCode + ")")
        onShareError: (requestCode, message) => appLog.add("shareError (" + requestCode + "): " + message)

        onFileUrlReceived: (url) => appLog.add("fileUrlReceived: " + url)
        onFileReceivedAndSaved: (url) => appLog.add("fileReceivedAndSaved: " + url)
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


        //
    }

    ////////////////////////////////////////////////////////////////////////////
}
