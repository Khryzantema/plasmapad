// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami

// A folder: a rounded tile previewing its first apps in a 3x3 grid, with the name below.
Item {
    id: root

    required property string label

    // The folder's app model; null until Kicker has made it available.
    property var appsModel: null
    property int tileSize: 120

    // Shown as selected (keyboard navigation).
    property bool highlighted: false

    readonly property int previewCount: Math.min(9, appsModel ? appsModel.count : 0)

    signal clicked()

    // Selection background, a little larger than the tile.
    Rectangle {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        radius: root.tileSize * 0.25
        color: Qt.rgba(1, 1, 1, root.highlighted ? 0.18 : 0)

        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Rectangle {
        id: tile

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.06)
        width: root.tileSize
        height: root.tileSize
        radius: root.tileSize * 0.22
        color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.30 : 0.22)
        scale: area.pressed ? 0.94 : 1

        Behavior on scale { NumberAnimation { duration: 90 } }

        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: root.tileSize * 0.05

            // Only the first nine apps are previewed, so only nine icons are created however
            // many apps the folder has. The icon is read from the model directly (decoration role).
            Repeater {
                model: root.previewCount

                delegate: Kirigami.Icon {
                    required property int index

                    width: root.tileSize * 0.25
                    height: width
                    source: root.appsModel.data(root.appsModel.index(index, 0), Qt.DecorationRole)
                }
            }
        }
    }

    Text {
        anchors {
            top: tile.bottom
            topMargin: Kirigami.Units.smallSpacing
            left: parent.left
            right: parent.right
        }
        text: root.label
        color: "white"
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
