// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker

// Search results as a vertical list: icon on the left, name in the middle.
//
// KRunner resets its whole model on every keystroke, which a ListView cannot animate (it would
// replay the entry animation for every row). So the runner's results are mirrored into a ListModel
// by diffing on the result name: rows that disappear fade out, new ones fade in, and rows that stay
// slide to their new place.
Item {
    id: root

    required property var applet

    // The text being searched for; an empty query means the results are not shown.
    property string query: ""

    readonly property bool active: query !== ""

    // The runner's merged result model (all runners in one list), once it exists. Rows are
    // identified by their position in it.
    property var source: null

    // The displayed results by key: { display, decoration, row }, where `row` is the position
    // in `source`. The ListModel only holds keys, which is what lets rows be tracked by identity.
    property var entries: ({})

    // `name` is the launched app's name.
    signal launched(string name)
    signal contextMenuRequested(var actions, int sourceRow, string favoriteId)

    // Moves the keyboard selection by `delta` rows, stopping at the ends.
    function moveCurrent(delta) {
        view.currentIndex = Math.max(0, Math.min(shown.count - 1, view.currentIndex + delta));
    }

    function launchCurrent() {
        launch(view.currentIndex);
    }

    function trigger(sourceRow, actionId, actionArgument) {
        return source !== null && source.trigger(sourceRow, actionId, actionArgument);
    }

    // Launches the result shown at `listIndex`.
    function launch(listIndex) {
        const row = sourceRow(listIndex);
        if (row >= 0 && trigger(row, "", null)) {
            launched(entries[shown.get(listIndex).key].display);
        }
    }

    // Position in `source` of the result shown at `listIndex`, or -1.
    function sourceRow(listIndex) {
        if (listIndex < 0 || listIndex >= shown.count) {
            return -1;
        }
        const entry = entries[shown.get(listIndex).key];
        return entry ? entry.row : -1;
    }

    // Brings the displayed list in line with the runner's current results: reads them through
    // `collector`, then removes, inserts and moves rows of `shown` to match.
    function sync() {
        if (!active) {
            return;
        }

        const next = {};
        const order = [];
        for (let row = 0; row < collector.count; ++row) {
            const item = collector.itemAt(row);
            if (!item) {
                continue;
            }
            // Results can share a name; a zero-width space makes the key unique without changing it
            // visibly.
            let key = item.display;
            while (next[key] !== undefined) {
                key += "\u200b";
            }
            next[key] = { display: item.display, decoration: item.decoration, row: row };
            order.push(key);
        }

        // Remove rows that are gone, from the end so indexes stay valid.
        for (let i = shown.count - 1; i >= 0; --i) {
            if (next[shown.get(i).key] === undefined) {
                shown.remove(i);
            }
        }

        // Then insert new rows and move existing ones into their new position.
        for (let i = 0; i < order.length; ++i) {
            let at = -1;
            for (let j = i; j < shown.count; ++j) {
                if (shown.get(j).key === order[i]) {
                    at = j;
                    break;
                }
            }
            if (at === -1) {
                shown.insert(i, { key: order[i] });
            } else if (at !== i) {
                shown.move(at, i, 1);
            }
        }

        entries = next;
        view.currentIndex = Math.max(0, Math.min(view.currentIndex, shown.count - 1));
    }

    onActiveChanged: {
        if (active) {
            syncTimer.restart();
        } else {
            shown.clear();
            entries = ({});
        }
    }

    // Only the application and system settings runners: this is an app launcher, not a general
    // KRunner front end.
    Kicker.RunnerModel {
        id: runner

        appletInterface: root.applet
        mergeResults: true
        runners: ["krunner_services", "krunner_systemsettings"]
        query: root.query

        onCountChanged: {
            if (count > 0 && root.source === null) {
                root.source = modelForRow(0);
            }
        }
    }

    // Reads the runner's rows. A model can only be read row by row through delegates, so this
    // invisible Repeater exposes each row's data (and its `model`, for the action list).
    Repeater {
        id: collector

        model: root.source

        delegate: Item {
            required property string display
            required property var decoration
            required property var model

            width: 0
            height: 0
        }

        onItemAdded: syncTimer.restart()
        onItemRemoved: syncTimer.restart()
    }

    // Waits for the burst of changes a new query causes before syncing once.
    Timer {
        id: syncTimer

        interval: 40
        onTriggered: root.sync()
    }

    ListModel {
        id: shown
    }

    ListView {
        id: view

        anchors.fill: parent
        model: shown
        clip: true
        spacing: Kirigami.Units.smallSpacing
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: 0

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: 220; easing.type: Easing.OutCubic }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 160; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; to: 0.94; duration: 160; easing.type: Easing.InCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: result

            required property int index
            required property string key

            readonly property var entry: root.entries[key] || null

            width: ListView.view.width
            height: Kirigami.Units.gridUnit * 3

            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.largeSpacing
                color: Qt.rgba(1, 1, 1, result.ListView.isCurrentItem ? 0.2 : (area.containsMouse ? 0.12 : 0.06))
            }

            Kirigami.Icon {
                anchors {
                    left: parent.left
                    leftMargin: Kirigami.Units.largeSpacing
                    verticalCenter: parent.verticalCenter
                }
                width: Kirigami.Units.iconSizes.large
                height: width
                source: result.entry ? result.entry.decoration : ""
            }

            Text {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 3
                    rightMargin: Kirigami.Units.iconSizes.large + Kirigami.Units.largeSpacing * 3
                    verticalCenter: parent.verticalCenter
                }
                text: result.entry ? result.entry.display : ""
                color: "white"
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.2)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: view.currentIndex = result.index
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        root.launch(result.index);
                        return;
                    }
                    const row = root.sourceRow(result.index);
                    const item = row >= 0 ? collector.itemAt(row) : null;
                    if (item) {
                        root.contextMenuRequested(item.model.actionList, row, item.model.favoriteId || "");
                    }
                }
            }
        }
    }
}
