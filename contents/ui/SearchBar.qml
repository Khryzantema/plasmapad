// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// The rounded search field. It never loses keyboard focus to the rest of the launcher, so the
// arrow keys, Tab and Enter are handled here and forwarded as signals.
Rectangle {
    id: root

    readonly property alias input: input
    property alias text: input.text

    // The text cursor stays hidden until something is typed or the bar is clicked.
    property bool typed: false

    // Phase of the cursor blink.
    property bool blinkOn: true

    // The clickable area is larger than the visible bar, centered on it, so clicking near it works.
    property real hitScaleX: 1.3
    property real hitScaleY: 3

    signal moveUp()
    signal moveDown()
    signal moveLeft()
    signal moveRight()
    signal accepted()

    height: Kirigami.Units.gridUnit * 2.2
    radius: height / 2
    color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.24 : 0.16)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.22)

    // The cursor is a custom delegate (to be able to hide it), and a custom delegate does not
    // blink by itself, so the blink is done here.
    Timer {
        id: blinkTimer

        interval: 530
        repeat: true
        running: root.typed && input.activeFocus
        onTriggered: root.blinkOn = !root.blinkOn
        onRunningChanged: root.blinkOn = true
    }

    // Sits below the text input, so clicks on the text still place the caret.
    MouseArea {
        x: -root.width * (root.hitScaleX - 1) / 2
        y: -root.height * (root.hitScaleY - 1) / 2
        width: root.width * root.hitScaleX
        height: root.height * root.hitScaleY
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        onClicked: {
            root.typed = true;
            input.forceActiveFocus();
        }
    }

    Kirigami.Icon {
        id: icon

        anchors {
            left: parent.left
            leftMargin: Kirigami.Units.largeSpacing
            verticalCenter: parent.verticalCenter
        }
        width: Kirigami.Units.iconSizes.small
        height: width
        source: "search"
        color: "white"
    }

    TextInput {
        id: input

        anchors {
            left: icon.right
            leftMargin: Kirigami.Units.smallSpacing * 2
            right: parent.right
            rightMargin: Kirigami.Units.largeSpacing
            verticalCenter: parent.verticalCenter
        }
        color: "white"
        selectionColor: Kirigami.Theme.highlightColor
        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.15)
        clip: true

        cursorDelegate: Rectangle {
            width: 1
            color: input.color
            opacity: root.typed && root.blinkOn ? 1 : 0
        }

        // The cursor is solid while it moves and blinks when it rests.
        onCursorPositionChanged: {
            root.blinkOn = true;
            blinkTimer.restart();
        }

        onTextChanged: {
            if (text !== "") {
                root.typed = true;
            }
        }

        TapHandler {
            onTapped: root.typed = true
        }

        Keys.onPressed: root.typed = true

        // Left/Right move the text caret while there is text, and navigate the folders otherwise.
        Keys.onLeftPressed: event => root.text === "" ? root.moveLeft() : event.accepted = false
        Keys.onRightPressed: event => root.text === "" ? root.moveRight() : event.accepted = false
        Keys.onTabPressed: root.moveRight()
        Keys.onBacktabPressed: root.moveLeft()
        Keys.onUpPressed: root.moveUp()
        Keys.onDownPressed: root.moveDown()
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()

        // Placeholder.
        Text {
            anchors.fill: parent
            text: i18n("Search")
            color: Qt.rgba(1, 1, 1, 0.55)
            font: input.font
            visible: input.text === "" && !input.inputMethodComposing
        }
    }
}
