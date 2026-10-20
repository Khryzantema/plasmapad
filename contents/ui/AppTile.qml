// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// An application inside an opened folder: its icon with the name below. Meant to be the delegate
// of a GridView, whose cell size it fills.
Item {
    id: root

    required property string label
    required property var iconSource
    property int iconSize: 64

    signal clicked()
    signal contextMenuRequested()

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    // Hover, press and keyboard-selection background.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        radius: Kirigami.Units.largeSpacing
        color: Qt.rgba(1, 1, 1, area.pressed ? 0.22 : (area.containsMouse || root.GridView.isCurrentItem ? 0.16 : 0))
    }

    // Icon and name are centered together as one block, so a one-line and a two-line name sit at
    // the same height.
    Column {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.smallSpacing * 2
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.iconSize
            height: root.iconSize
            source: root.iconSource
        }

        Text {
            width: parent.width
            text: root.label
            color: "white"
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.contextMenuRequested() : root.clicked()
    }
}
