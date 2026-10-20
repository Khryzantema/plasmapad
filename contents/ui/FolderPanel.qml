// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// The opened folder: a dark scrim over the launcher and a frosted panel with the folder's apps.
// It is always present and fades in and out; use open() and close().
Item {
    id: root

    // Sizes, set by the parent so everything scales with the launcher's icon size.
    property int iconSize: 64
    property int cellWidth: 96
    property int cellHeight: 120
    property int cornerRadius: 24

    // What is being shown. These are kept for a moment after close() so the panel does not empty
    // out while it fades.
    property var appsModel: null
    property string label: ""

    // True for Favorites and Recent: they are not categories and can be empty.
    property bool special: false

    property bool opened: false

    signal closeRequested()
    signal appClicked(int row)
    signal contextMenuRequested(var actions, int row, string favoriteId)

    // `selectFirst` selects the first app (the folder was opened with the keyboard).
    function open(folderLabel, model, selectFirst, isSpecial) {
        clearTimer.stop();
        label = folderLabel;
        special = isSpecial === true;
        appsModel = model;
        appsView.currentIndex = selectFirst ? 0 : -1;
        opened = true;
    }

    function close() {
        opened = false;
        clearTimer.restart();
    }

    // Keyboard selection. dx/dy are -1, 0 or 1; the first move selects the first app.
    function move(dx, dy) {
        if (appsView.count === 0) {
            return;
        }
        if (appsView.currentIndex < 0) {
            appsView.currentIndex = 0;
        } else if (dx > 0) {
            appsView.moveCurrentIndexRight();
        } else if (dx < 0) {
            appsView.moveCurrentIndexLeft();
        } else if (dy > 0) {
            appsView.moveCurrentIndexDown();
        } else if (dy < 0) {
            appsView.moveCurrentIndexUp();
        }
    }

    function launchCurrent() {
        if (appsView.currentIndex >= 0) {
            appClicked(appsView.currentIndex);
        }
    }

    visible: opacity > 0
    opacity: opened ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 160 } }

    // Clears the content once the fade-out is over (it takes 160 ms).
    Timer {
        id: clearTimer

        interval: 260
        onTriggered: {
            root.appsModel = null;
            root.label = "";
        }
    }

    // Dims everything behind the panel.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    // Clicking outside the panel closes the folder.
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: panel

        // The panel fits its content: up to six apps per row, as many rows as needed.
        readonly property int count: root.appsModel ? root.appsModel.count : 1
        readonly property int columns: Math.max(1, Math.min(count, 6))
        readonly property int rows: Math.max(1, Math.ceil(count / columns))

        anchors.centerIn: parent
        width: Math.min(root.width * 0.9, columns * root.cellWidth + Kirigami.Units.largeSpacing * 4)
        height: Math.min(root.height * 0.8, rows * root.cellHeight + title.height + Kirigami.Units.largeSpacing * 4)
        radius: root.cornerRadius
        color: Qt.rgba(1, 1, 1, 0.3)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.4)
        scale: root.opened ? 1 : 0.9

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Swallows clicks so they do not reach the scrim and close the folder.
        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: title

            anchors {
                top: parent.top
                topMargin: Kirigami.Units.largeSpacing * 1.5
                horizontalCenter: parent.horizontalCenter
            }
            text: root.label
            color: "white"
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.9)
            font.weight: Font.Medium
        }

        // Shown inside an empty Favorites or Recent folder.
        Text {
            anchors.centerIn: parent
            visible: panel.count === 0
            text: root.special ? i18n("Nothing here yet") : ""
            color: Qt.rgba(1, 1, 1, 0.7)
            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.2)
        }

        GridView {
            id: appsView

            anchors {
                top: title.bottom
                topMargin: Kirigami.Units.largeSpacing
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.largeSpacing
                horizontalCenter: parent.horizontalCenter
            }
            width: panel.columns * root.cellWidth
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // -1: nothing is selected until the keyboard is used.
            currentIndex: -1
            model: root.appsModel

            delegate: AppTile {
                required property int index
                required property string display
                required property var decoration
                required property var model

                iconSize: root.iconSize
                label: display
                iconSource: decoration

                onClicked: root.appClicked(index)
                // `model.actionList` and `model.favoriteId` are roles of Kicker's app models.
                onContextMenuRequested: root.contextMenuRequested(model.actionList, index, model.favoriteId || "")
            }
        }
    }
}
