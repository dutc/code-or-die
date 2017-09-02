SHELL = $(PWD)/env /bin/zsh

DATABASE = code-or-die

.PHONY: test
test:
	which psql jinja2 || exit 1
	psql -d $(DATABASE) < layout.sql
	psql -d $(DATABASE) <<( ./bitemporal.sh "$(DATABASE)" )
	psql -d $(DATABASE) < dummy.sql

.PHONY: dump.sql
dump.sql:
	tables=(objects.{civilizations,systems,ships},names.{civilizations,systems,ships},orders.{systems,ships},events.{build,transit,attack,warp}) && \
	pg_dump -d $(DATABASE) --data-only --column-inserts $${(z)tables/#/-t } > dump.sql

.PHONY: start-db stop-db db-shell run-db
start-db:
	pg_ctl -D $(PWD)/database -l $(PWD)/database-logs/"`date`.log" start
stop-db:
	pg_ctl -D database stop
db-shell:
	PSQLRC=psqlrc psql -d $(DATABASE)

.PHONY: start-flask-debug
run-flask-debug:
	FLASK_CONFIG=config.py FLASK_APP=api FLASK_DEBUG=1 PYTHONPATH=. flask run

.PHONY: flask-shell
flask-shell:
	FLASK_CONFIG=config.py FLASK_APP=api FLASK_DEBUG=1 PYTHONPATH=. flask shell
