LOGFILE=postgresql.log
SOCKDIR=$(shell pwd)
DBDIR=tezos
DBNAME=tezos

all:
	psql -h $(SOCKDIR) -d $(DBNAME) -c '\i schema.sql'

init:
	pg_ctl init -D $(DBDIR) -o --no-locale
	pg_ctl -D $(DBDIR) -l $(LOGFILE) -o "-k $(SOCKDIR)" start
	echo "Wait 5 seconds for postgres initialization"
	sleep 5
	createdb -h $(SOCKDIR) $(DBNAME)

start:
	pg_ctl -D $(DBDIR) -l $(LOGFILE) -o "-k $(SOCKDIR)" start

stop:
	pg_ctl -D $(DBDIR) -o "-k $(SOCKDIR)" stop

.PHONY: clean
clean:
	rm -rf tezos
