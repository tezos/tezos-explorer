LOGFILE=postgresql.log
PGHOST=$(shell pwd)
DATADIR=tezos
PGDATABASE=tezos

.PHONY: all init start stop clean

all:
	dropdb --if-exists -h $(PGHOST) $(PGDATABASE)
	createdb -h $(PGHOST) $(PGDATABASE) -E UTF8
	PGHOST=$(PGHOST) PGDATABASE=$(PGDATABASE) psql -c '\i schema.sql'

init:
	initdb -D $(DATADIR) --locale=en_US.UTF8
	pg_ctl -D $(DATADIR) -l $(LOGFILE) -o "-k $(PGHOST)" start
	echo "Wait 5 seconds for postgres initialization"
	sleep 5

start:
	pg_ctl -D $(DATADIR) -l $(LOGFILE) -o "-k $(PGHOST)" start

stop:
	pg_ctl -D $(DATADIR) -o "-k $(PGHOST)" stop

clean:
	rm -rf tezos
