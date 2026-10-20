// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.private.kicker as Kicker

import "code/tools.js" as Tools

// PlasmaPad entry point: owns the data models, the wallpaper lookup and the launcher window, and
// exposes the panel button. The launcher itself lives in its own full-screen window.
PlasmoidItem {
    id: root

    // The window currently in use (see `launcherLoader`); both window types share one interface:
    // `opened`, `open()`, `close()` and `appUsed(category)`.
    readonly property var launcher: launcherLoader.item

    // Size at which the wallpaper is decoded: the screen plus the blur margin on each side.
    readonly property size wallpaperSize: Qt.size(Screen.width + 2 * Tools.backdropBleed,
                                                  Screen.height + 2 * Tools.backdropBleed)

    // How many apps were launched from each category (category name -> count), persisted in the
    // widget configuration as JSON. Used to place the most used categories in the center.
    readonly property var categoryUsage: {
        try {
            return JSON.parse(Plasmoid.configuration.categoryUsage);
        } catch (error) {
            return {};
        }
    }

    Plasmoid.icon: Tools.iconOrDefault(Plasmoid.formFactor, Plasmoid.configuration.icon)
    Plasmoid.onActivated: toggle()

    // The launcher is its own window, so activating the widget (Super key, click) must not also
    // expand a Plasma popup.
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation

    function recordUse(category) {
        if (category === "") {
            return;
        }
        const usage = Object.assign({}, categoryUsage);
        usage[category] = (usage[category] || 0) + 1;
        Plasmoid.configuration.categoryUsage = JSON.stringify(usage);
    }

    function toggle() {
        if (!launcher) {
            return;
        }
        if (launcher.opened) {
            launcher.close();
        } else {
            // Re-read the wallpaper on every opening: it may have been changed since the last one.
            wallpaperProvider.refresh(Screen.width, Screen.height);
            launcher.open();
        }
    }

    // Categories and their apps: the same model Kickoff and Kicker use, so installing or removing
    // an application updates the launcher by itself.
    Kicker.RootModel {
        id: appsModel

        autoPopulate: false
        appletInterface: root
        showAllApps: false
        showAllAppsCategorized: true
        showTopLevelItems: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false

        Component.onCompleted: refresh()
    }

    // Pinned apps, stored in this widget's own configuration.
    Kicker.SimpleFavoritesModel {
        id: favoritesStore

        enabled: true
        favorites: Plasmoid.configuration.favorites

        // The comparison avoids a write -> change -> write loop (it froze plasmashell once).
        onFavoritesChanged: {
            if (JSON.stringify(favorites) !== JSON.stringify(Plasmoid.configuration.favorites)) {
                Plasmoid.configuration.favorites = favorites;
            }
        }
    }

    // Recently used apps, from the system's own usage statistics (KActivities).
    Kicker.RecentUsageModel {
        id: recentStore

        shownItems: Kicker.RecentUsageModel.OnlyApps
        ordering: Kicker.RecentUsageModel.Recent
    }

    WallpaperProvider {
        id: wallpaperProvider

        imageSize: root.wallpaperSize

        Component.onCompleted: refresh(Screen.width, Screen.height)
    }

    // The window type follows the "blur only" setting. The two components below pass the same
    // data on purpose: ids named like the window's own properties would resolve to those
    // properties instead, so the models and the provider have distinct ids.
    Loader {
        id: launcherLoader

        sourceComponent: Plasmoid.configuration.blurOnly ? blurWindow : dialogWindow
    }

    Component {
        id: dialogWindow

        LaunchpadDialogWindow {
            applet: root
            rootModel: appsModel
            favoritesModel: favoritesStore
            recentModel: recentStore
            wallpaper: wallpaperProvider.url
            wallpaperSize: root.wallpaperSize
            screenGeometry: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
            usage: root.categoryUsage
            iconScale: Plasmoid.configuration.launcherIconScale / 100

            onAppUsed: category => root.recordUse(category)
        }
    }

    Component {
        id: blurWindow

        // Kicker.DashboardWindow sizes and places itself, so no screenGeometry here.
        LaunchpadBlurWindow {
            applet: root
            rootModel: appsModel
            favoritesModel: favoritesStore
            recentModel: recentStore
            wallpaper: wallpaperProvider.url
            wallpaperSize: root.wallpaperSize
            usage: root.categoryUsage
            iconScale: Plasmoid.configuration.launcherIconScale / 100

            onAppUsed: category => root.recordUse(category)
        }
    }

    // The same button is used as the full representation so that Plasma has no popup to open.
    Component {
        id: panelButton

        PanelButton {
            onClicked: root.toggle()
        }
    }

    compactRepresentation: panelButton
    fullRepresentation: panelButton
}
