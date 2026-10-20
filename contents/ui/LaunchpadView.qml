// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Effects

import org.kde.kirigami as Kirigami

// The launcher layout. From back to front: the search bar, the folder grid (replaced by the
// results while there is a search), the opened folder, and the context menu.
Item {
    id: root

    required property var rootModel
    required property var applet

    // Data, passed through from main.qml.
    property var favoritesModel: null
    property var recentModel: null
    property var usage: ({})
    property real iconScale: 1

    // What the context menu blurs: the content behind it (backdrop and launcher).
    property Item blurSource: null

    readonly property alias searchInput: searchBar.input
    readonly property bool searching: searchBar.text.trim() !== ""

    // Everything scales with the folder tile: the smaller of 1/10 of the width and 1/6.5 of the
    // height (so ten tiles fit across and six and a half down), times the user's icon scale.
    readonly property int tileSize: Math.round(Math.min(width / 10, height / 6.5) * iconScale)
    readonly property int appIconSize: Math.round(tileSize * 0.62)

    signal closeRequested()

    // An app was launched; `category` is the folder it came from ("" when unknown).
    signal appLaunched(string category)

    // Clears the search, the keyboard selection and the opened folder.
    function reset() {
        searchBar.text = "";
        searchBar.typed = false;
        folders.current = folders.none;
        folderPanel.close();
    }

    // Esc closes one layer at a time: the search, then the folder. Returns false when there is
    // nothing left to close, so the launcher itself should close.
    function handleEscape() {
        if (searching) {
            searchBar.text = "";
        } else if (folderPanel.opened) {
            folderPanel.close();
        } else {
            return false;
        }
        return true;
    }

    // Arrow keys: act on whichever layer is in front. dx/dy are -1, 0 or 1.
    function navigate(dx, dy) {
        if (searching) {
            results.moveCurrent(dy !== 0 ? dy : dx);
        } else if (folderPanel.opened) {
            folderPanel.move(dx, dy);
        } else {
            folders.move(dx, dy);
        }
    }

    // Enter: open or launch the selected item of the layer in front.
    function activate() {
        if (searching) {
            results.launchCurrent();
        } else if (folderPanel.opened) {
            folderPanel.launchCurrent();
        } else {
            folders.openCurrent();
        }
    }

    // Finds the folder that contains an app, for counting its use. Search results do not say
    // which folder they came from, so it is matched by name (exact first, then partial).
    function categoryOf(name) {
        const wanted = name.toLowerCase();
        let partial = "";
        for (let row = 0; row < rootModel.count; ++row) {
            const model = rootModel.modelForRow(row);
            for (let i = 0; model && i < model.count; ++i) {
                const display = String(model.data(model.index(i, 0), Qt.DisplayRole)).toLowerCase();
                if (display === wanted) {
                    return rootModel.labelForRow(row);
                }
                if (partial === "" && (display.includes(wanted) || wanted.includes(display))) {
                    partial = rootModel.labelForRow(row);
                }
            }
        }
        return partial;
    }

    // Adds "Add to / Remove from Favorites" to an app's action list. Kicker's own list has no such
    // entry because favorites are handled by the launcher, not by the app model.
    function withFavoriteAction(actions, favoriteId) {
        if (!favoritesModel || favoriteId === "") {
            return actions;
        }
        const favorite = favoritesModel.isFavorite(favoriteId);
        return actions.concat([
            { type: "separator" },
            {
                text: favorite ? i18n("Remove from Favorites") : i18n("Add to Favorites"),
                icon: favorite ? "bookmark-remove" : "bookmark-new",
                actionId: favorite ? "_plasmapad_favorite_remove" : "_plasmapad_favorite_add",
                actionArgument: favoriteId
            }
        ]);
    }

    // Runs the action chosen in the context menu: the favorites ones here, everything else on the
    // app's own model. `context` is what was passed to ContextMenuHost.openFor().
    function triggerFromMenu(context, actionId, actionArgument) {
        if (actionId === "_plasmapad_favorite_add") {
            favoritesModel.addFavorite(actionArgument);
            return;
        }
        if (actionId === "_plasmapad_favorite_remove") {
            favoritesModel.removeFavorite(actionArgument);
            return;
        }
        const model = context.model;
        if (model && model.trigger(context.row, actionId, actionArgument)) {
            appLaunched("");
        }
    }

    // The app list was rebuilt (for example an app was installed): an open folder would be showing
    // a model that no longer exists.
    Connections {
        target: root.rootModel

        function onRefreshed() {
            folders.current = folders.none;
            folderPanel.close();
        }
    }

    // Clicking empty space closes the launcher.
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    SearchBar {
        id: searchBar

        anchors {
            top: parent.top
            topMargin: Math.round(root.height * 0.05)
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(root.width * 0.36, Kirigami.Units.gridUnit * 24)

        onMoveUp: root.navigate(0, -1)
        onMoveDown: root.navigate(0, 1)
        onMoveLeft: root.navigate(-1, 0)
        onMoveRight: root.navigate(1, 0)
        onAccepted: root.activate()
    }

    SearchResults {
        id: results

        anchors {
            top: searchBar.bottom
            topMargin: Kirigami.Units.largeSpacing * 2
            bottom: parent.bottom
            bottomMargin: Math.round(root.height * 0.06)
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(root.width * 0.5, Kirigami.Units.gridUnit * 36)
        visible: root.searching
        applet: root.applet
        query: searchBar.text.trim()

        onLaunched: name => root.appLaunched(root.categoryOf(name))
        onContextMenuRequested: (actions, row, favoriteId) =>
            contextMenu.openFor(withFavoriteAction(actions, favoriteId), { model: results.source, row: row })
    }

    FolderGrid {
        id: folders

        // A little below the center, to balance the search bar above.
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Math.round(root.height * 0.03)
        width: root.width
        height: Math.min(rows * cellHeight, root.height * 0.74)
        maxWidth: Math.min(root.width * 0.86, cellWidth * 7)
        rootModel: root.rootModel
        favoritesModel: root.favoritesModel
        recentModel: root.recentModel
        usage: root.usage
        tileSize: root.tileSize
        enabled: !folderPanel.opened && !root.searching
        visible: opacity > 0
        opacity: root.searching ? 0 : (folderPanel.opened ? 0.5 : 1)

        Behavior on opacity { NumberAnimation { duration: 150 } }

        // While a folder is open the grid behind it is blurred, so it does not show through the
        // translucent panel. The layer only exists while that is the case.
        layer.enabled: folderPanel.opened
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 48
        }

        onFolderClicked: (row, appsModel, viaKeyboard) =>
            folderPanel.open(folders.labelFor(row), appsModel, viaKeyboard, folders.isSpecial(row))
    }

    FolderPanel {
        id: folderPanel

        anchors.fill: parent
        enabled: opened && !root.searching
        iconSize: root.appIconSize
        cellWidth: Math.round(root.tileSize * 1.35)
        cellHeight: root.appIconSize + Kirigami.Units.gridUnit * 3.4
        cornerRadius: root.tileSize * 0.3

        onCloseRequested: close()
        onAppClicked: row => {
            appsModel.trigger(row, "", null);
            // Favorites and Recent are not categories, so launching from them is not counted.
            root.appLaunched(special ? "" : label);
        }
        onContextMenuRequested: (actions, row, favoriteId) =>
            contextMenu.openFor(withFavoriteAction(actions, favoriteId), { model: appsModel, row: row })
    }

    ContextMenuHost {
        id: contextMenu

        blurSource: root.blurSource

        onActionTriggered: (context, actionId, actionArgument) => root.triggerFromMenu(context, actionId, actionArgument)
    }
}
