// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.iconthemes as KIconThemes

import "code/tools.js" as Tools

// Settings page. Plasma matches each `cfg_<name>` property here to the entry <name> of
// config/main.xml: it fills it with the saved value, and saves it back when OK or Apply is
// pressed. The `cfg_<name>Default` properties are what "Defaults" restores; Plasma sets them
// itself and warns if they are missing.
KCM.SimpleKCM {
    property string cfg_icon: Plasmoid.configuration.icon
    property string cfg_iconDefault: Tools.defaultIconName
    property bool cfg_autoIconSize: Plasmoid.configuration.autoIconSize
    property bool cfg_autoIconSizeDefault: true
    property int cfg_iconSize: Plasmoid.configuration.iconSize
    property int cfg_iconSizeDefault: 32
    property bool cfg_blurOnly: Plasmoid.configuration.blurOnly
    property bool cfg_blurOnlyDefault: false
    property int cfg_launcherIconScale: Plasmoid.configuration.launcherIconScale
    property int cfg_launcherIconScaleDefault: 100

    Kirigami.FormLayout {
        QQC2.Button {
            id: iconButton

            Kirigami.FormData.label: i18n("Panel icon:")

            implicitWidth: implicitHeight
            implicitHeight: Kirigami.Units.iconSizes.large + Kirigami.Units.smallSpacing * 2

            icon.name: Tools.iconOrDefault(Plasmoid.formFactor, cfg_icon)
            icon.width: Kirigami.Units.iconSizes.large
            icon.height: Kirigami.Units.iconSizes.large

            onPressed: iconMenu.visible ? iconMenu.close() : iconMenu.open()

            QQC2.Menu {
                id: iconMenu

                y: iconButton.height

                QQC2.MenuItem {
                    text: i18n("Choose…")
                    icon.name: "document-open-folder"
                    onClicked: iconDialog.open()
                }
                QQC2.MenuItem {
                    text: i18n("Reset to default icon")
                    icon.name: "edit-undo"
                    onClicked: cfg_icon = Tools.defaultIconName
                }
                QQC2.MenuItem {
                    text: i18n("Remove icon")
                    icon.name: "edit-delete"
                    onClicked: cfg_icon = ""
                }
            }

            KIconThemes.IconDialog {
                id: iconDialog
                onIconNameChanged: (iconName) => cfg_icon = iconName || Tools.defaultIconName
            }
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Icon size:")
            text: i18n("Fit to panel size")
            checked: cfg_autoIconSize
            onToggled: cfg_autoIconSize = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Custom size:")
            enabled: !cfg_autoIconSize

            QQC2.Slider {
                id: iconSizeSlider
                Layout.fillWidth: true
                from: 16
                to: 64
                stepSize: 1
                value: cfg_iconSize
                onMoved: cfg_iconSize = value
            }

            QQC2.Label {
                text: i18n("%1 px", Math.round(iconSizeSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: metrics.advanceWidth
                TextMetrics {
                    id: metrics
                    text: i18n("88 px")
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.Switch {
            Kirigami.FormData.label: i18n("Background:")
            text: i18n("Blur only (hide the wallpaper)")
            checked: cfg_blurOnly
            onToggled: cfg_blurOnly = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Launcher icon size:")

            QQC2.Slider {
                id: scaleSlider

                Layout.fillWidth: true
                from: 60
                to: 160
                stepSize: 5
                value: cfg_launcherIconScale
                onMoved: cfg_launcherIconScale = value
            }

            QQC2.Label {
                text: i18n("%1%", Math.round(scaleSlider.value))
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: scaleMetrics.advanceWidth

                TextMetrics {
                    id: scaleMetrics

                    text: i18n("888%")
                }
            }
        }
    }
}
