import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import MobileUI
import MobileSharing

Window {
    id: appWindow

    minimumWidth: 480
    minimumHeight: 960

    visible: true
    color: "#eeeeee"

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    property bool isHdpi: (utilsScreen.screenDpi >= 128 || utilsScreen.screenPar >= 2.0)
    property bool isDesktop: (Qt.platform.os !== "ios" && Qt.platform.os !== "android")
    property bool isMobile: (Qt.platform.os === "ios" || Qt.platform.os === "android")
    property bool isPhone: ((Qt.platform.os === "ios" || Qt.platform.os === "android") && (utilsScreen.screenSize < 7.0))
    property bool isTablet: ((Qt.platform.os === "ios" || Qt.platform.os === "android") && (utilsScreen.screenSize >= 7.0))

    // Mobile stuff ////////////////////////////////////////////////////////////

    // 1 = Qt.PortraitOrientation, 2 = Qt.LandscapeOrientation
    // 4 = Qt.InvertedPortraitOrientation, 8 = Qt.InvertedLandscapeOrientation
    property int screenOrientation: Screen.primaryOrientation
    property int screenOrientationFull: Screen.orientation

    // MobileUI keeps these up to date on its own, reacting to orientation and
    // window visibility changes (see thirdparty/MobileUI/).
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
        MobileUI.navbarTheme = MobileUI.Dark
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

    // UI //////////////////////////////////////////////////////////////////////

    FocusScope {
        id: appContent

        anchors.top: appHeader.bottom
        anchors.left: parent.left
        anchors.leftMargin: screenPaddingLeft
        anchors.right: parent.right
        anchors.rightMargin: screenPaddingRight
        anchors.bottom: Math.max(appWindow.screenPaddingNavbar, appWindow.screenPaddingBottom)

        focus: true
        Keys.onBackPressed: appWindow.backAction()

        //
    }

    ////////////////////////////////////////////////////////////////////////////
}
