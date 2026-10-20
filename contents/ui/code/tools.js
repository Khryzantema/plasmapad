// SPDX-License-Identifier: GPL-2.0-or-later

// Constants and helpers shared by several QML files. `.pragma library` makes this a single
// instance, so every importer sees the same values.
.pragma library

.import org.kde.plasma.core as PlasmaCore

// Panel button icon used when none is configured. Keep in sync with the default in config/main.xml.
var defaultIconName = "start-here-kde-symbolic";

// Pixels by which the wallpaper (and its blur) extend past the screen on every side. The blur
// samples neighboring pixels, so without this margin it would lighten the screen edges. The
// wallpaper is also decoded at screen size + 2 * backdropBleed so it is ready in the pixmap cache.
var backdropBleed = 96;

// Same rule as Kickoff: a vertical panel must never end up without an icon, because the compact
// button has no text to fall back to there.
function iconOrDefault(formFactor, preferredIconName) {
    if (formFactor === PlasmaCore.Types.Vertical && !preferredIconName) {
        return defaultIconName;
    }
    return preferredIconName;
}
