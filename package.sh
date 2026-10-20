#!/bin/sh
# Builds a .plasmoid release package (a zip of the widget) in the current directory.
# Install it with: kpackagetool6 -t Plasma/Applet -i io.github.khryzantema.plasmapad-<version>.plasmoid
set -e
cd "$(dirname "$0")"

version=$(python3 -c 'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')
out="io.github.khryzantema.plasmapad-$version.plasmoid"

# Make sure the translations are up to date before packing them.
sh po/build.sh

rm -f "$out"
zip -r -q "$out" metadata.json contents LICENSE README.md
echo "Created $out"
