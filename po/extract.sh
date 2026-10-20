#!/bin/sh
# Regenerates the translation template po/plasma_applet_io.github.khryzantema.plasmapad.pot from the QML sources.
cd "$(dirname "$0")/.." || exit 1
find contents -name '*.qml' | sort | xargs xgettext --from-code=UTF-8 --language=JavaScript --keyword=i18n \
    --package-name=io.github.khryzantema.plasmapad --add-comments --no-wrap --sort-by-file \
    -o po/plasma_applet_io.github.khryzantema.plasmapad.pot
