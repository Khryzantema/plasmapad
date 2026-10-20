// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "code/tools.js" as Tools

// The button shown in the panel, modeled on Kickoff's: the configured icon, or the default one
// when that icon does not exist.
MouseArea {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool fitToPanel: Plasmoid.configuration.autoIconSize

    // Fitting to the panel: the side along the panel is square with the panel thickness (which
    // Plasma gives as `height` on a horizontal panel and `width` on a vertical one), and -1 lets
    // the other side be decided by the panel. Otherwise the configured size is used.
    Layout.minimumWidth: Kirigami.Units.iconSizes.small
    Layout.minimumHeight: Kirigami.Units.iconSizes.small
    Layout.preferredWidth: fitToPanel ? (vertical ? -1 : height) : Plasmoid.configuration.iconSize
    Layout.preferredHeight: fitToPanel ? (vertical ? width : -1) : Plasmoid.configuration.iconSize

    hoverEnabled: true

    Kirigami.Icon {
        id: icon

        anchors.fill: parent
        source: Plasmoid.icon
        active: root.containsMouse
        visible: valid
    }

    // Fallback, shown only while the configured icon is invalid.
    Kirigami.Icon {
        anchors.fill: parent
        source: icon.valid ? "" : Tools.defaultIconName
        active: root.containsMouse
        visible: source !== ""
    }
}
