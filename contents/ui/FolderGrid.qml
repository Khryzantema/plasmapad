// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

// The grid of folders: Favorites, Recent and one folder per category. Every row is centered,
// including an incomplete last one.
//
// Folders are identified by a "folder id": a category's row number in the app model (0, 1, ...),
// or one of the negative ids below for the two special folders.
Flickable {
    id: root

    required property var rootModel
    property var favoritesModel: null
    property var recentModel: null
    property var usage: ({})
    property int tileSize: 120

    // Cell = tile plus breathing room around it; the grid never gets wider than `maxWidth`.
    property int cellWidth: Math.round(tileSize * 1.55)
    property int maxWidth: width

    // Folder ids of the special folders, and "nothing selected" for the keyboard selection
    // (it cannot be -1, which is Favorites).
    readonly property int favoritesId: -1
    readonly property int recentId: -2
    readonly property int none: -100

    // The folder selected with the keyboard, or `none`.
    property int current: none

    readonly property int cellHeight: Math.round(cellWidth * 1.12)
    readonly property int folderCount: rootModel.count + 2
    readonly property int columns: Math.max(1, Math.min(folderCount, cellWidth > 0 ? Math.floor(maxWidth / cellWidth) : 1))
    readonly property int rows: Math.ceil(folderCount / columns)

    // The folder ids of each row. Favorites and Recent take the center of the top row and the
    // categories fan out from there, the most used first (natural order while nothing is used yet).
    readonly property var layout: buildLayout(columns, usage)

    // Sub-models are only available once a view has visited the row, so tiles are bound to
    // `revision` (bumped while polling) and `generation` (bumped when the app list is rebuilt, which
    // invalidates every sub-model) to look them up again.
    property int revision: 0
    property int generation: 0

    signal folderClicked(int row, var appsModel, bool viaKeyboard)

    function isSpecial(id) {
        return id < 0;
    }

    function labelFor(id) {
        return id === favoritesId ? i18n("Favorites") : id === recentId ? i18n("Recent") : rootModel.labelForRow(id);
    }

    function modelFor(id) {
        return id === favoritesId ? favoritesModel : id === recentId ? recentModel : rootModel.modelForRow(id);
    }

    // Arranges items, sorted by priority, so the first goes in the middle and the next ones
    // alternate to its right and left: [a, b, c, d, e] becomes [e, c, a, b, d].
    function centerOut(sorted) {
        const count = sorted.length;
        const middle = Math.floor((count - 1) / 2);
        const arranged = new Array(count);
        arranged[middle] = sorted[0];
        for (let k = 1; k < count; ++k) {
            const offset = Math.ceil(k / 2);
            arranged[k % 2 === 1 ? middle + offset : middle - offset] = sorted[k];
        }
        return arranged;
    }

    // Splits all folders into rows of `perRow` and arranges every row center-out.
    function buildLayout(perRow, usageMap) {
        const categories = [];
        let total = 0;
        for (let row = 0; row < rootModel.count; ++row) {
            const score = usageMap[rootModel.labelForRow(row)] || 0;
            total += score;
            categories.push({ row: row, score: score });
        }
        // Most used first; ties and the no-data case keep the natural order.
        if (total > 0) {
            categories.sort((a, b) => b.score - a.score || a.row - b.row);
        }
        const ordered = [favoritesId, recentId].concat(categories.map(category => category.row));

        // `perRow` is 0 while the grid has no size yet; a zero step would loop forever.
        const step = Math.max(1, perRow);
        const lines = [];
        for (let start = 0; start < ordered.length; start += step) {
            lines.push(centerOut(ordered.slice(start, start + step)));
        }
        return lines;
    }

    function lineOf(id) {
        for (let line = 0; line < layout.length; ++line) {
            if (layout[line].indexOf(id) >= 0) {
                return line;
            }
        }
        return -1;
    }

    // Moves the keyboard selection. dx/dy are -1, 0 or 1. The first move selects the middle of
    // the top row, which is where Favorites and Recent are.
    function move(dx, dy) {
        if (layout.length === 0) {
            return;
        }
        if (current === none) {
            const first = layout[0];
            current = first[Math.floor((first.length - 1) / 2)];
            return;
        }

        const line = lineOf(current);
        const column = layout[line].indexOf(current);
        if (dy !== 0) {
            const target = line + dy;
            if (target < 0 || target >= layout.length) {
                return;
            }
            // Rows are centered, so shift by half the difference in length to stay in the same
            // visual column.
            const shifted = column + (layout[target].length - layout[line].length) / 2;
            current = layout[target][Math.max(0, Math.min(layout[target].length - 1, Math.round(shifted)))];
        } else {
            const target = column + dx;
            if (target >= 0 && target < layout[line].length) {
                current = layout[line][target];
            }
        }
    }

    function openCurrent() {
        if (current !== none) {
            folderClicked(current, modelFor(current), true);
        }
    }

    // Keeps the selected folder in view when the grid scrolls.
    onCurrentChanged: {
        const line = lineOf(current);
        if (line < 0) {
            return;
        }
        const top = line * cellHeight;
        if (top < contentY) {
            contentY = top;
        } else if (top + cellHeight > contentY + height) {
            contentY = top + cellHeight - height;
        }
    }

    contentWidth: width
    contentHeight: rows * cellHeight
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    // The app list was rebuilt: look every folder's sub-model up again.
    Connections {
        target: root.rootModel

        function onRefreshed() {
            root.generation++;
            root.revision = 0;
        }
    }

    // Visiting every row is what makes modelForRow() return a model, so this hidden Repeater
    // (one empty item per row) is not decoration. It is recreated whenever the model is rebuilt.
    Repeater {
        model: root.rootModel
        delegate: Item {
            width: 0
            height: 0
        }
    }

    // Polls until every category has its sub-model, then stops (revision 40 means "done"; it also
    // gives up after 40 tries, about six seconds).
    Timer {
        interval: 150
        repeat: true
        running: root.folderCount > 0 && root.revision < 40
        onTriggered: {
            let missing = false;
            for (let row = 0; row < root.rootModel.count && !missing; ++row) {
                missing = root.rootModel.modelForRow(row) === null;
            }
            ++root.revision;
            if (!missing) {
                root.revision = 40;
            }
        }
    }

    Column {
        width: root.width

        Repeater {
            model: root.layout.length

            delegate: Row {
                id: line

                required property int index

                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: root.layout[line.index]

                    delegate: FolderTile {
                        id: tile

                        required property int modelData
                        readonly property int row: modelData

                        width: root.cellWidth
                        height: root.cellHeight
                        tileSize: root.tileSize
                        label: root.labelFor(row)
                        highlighted: root.current === row
                        appsModel: {
                            // Evaluated again whenever either counter changes.
                            void root.revision;
                            void root.generation;
                            return root.modelFor(row);
                        }

                        onClicked: root.folderClicked(row, appsModel, false)
                    }
                }
            }
        }
    }
}
