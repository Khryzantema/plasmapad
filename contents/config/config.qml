// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick

import org.kde.plasma.configuration as PlasmaConfig

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
}
