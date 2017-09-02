#!/bin/zsh

export PYTHONIOENCODING='utf-8'

database=${1:?no database specified}

jinja2 --format=yaml bitemporal.sql.template <(
echo 'tables:'
(psql -q -d $database -t -A -F'.' <<EOF
    select table_schema, table_name
    from information_schema.tables
    where table_schema not in ('information_schema', 'pg_catalog')
    and table_schema not in ('history')
    and table_type <> 'VIEW'
EOF
) | sed -r 's/^/ - /'
)
