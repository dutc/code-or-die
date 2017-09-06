#!/bin/zsh

export PYTHONIOENCODING='utf-8'

root_dir="$(readlink -f "$(dirname "$0")")"
database=${1:?no database specified}

jinja2 --format=json "$root_dir/orm.sql.template" <<-EOJ
{"tables": [
      ["Ship", "ship", "objects.ships"]
    , ["System", "system", "objects.systems"]
    , ["Civilization", "civilization", "objects.civilizations"]
]}
EOJ
