.PHONY: start-dev
start-dev:
	docker-compose \
		-f deployments/postgres.docker-compose.yaml \
		--env-file=deployments/.env \
		up -d

args=
.PHONY: stop-dev
stop-dev:
	docker-compose \
		-f deployments/postgres.docker-compose.yaml \
		--env-file=deployments/.env \
		down $(args)

.PHONY: run-ut
run-ut:
	ginkgo ./...

.PHONY: run-app
run-ut:
	go run cmd/main.go

file=
.PHONY: dump-bd
dump-bd:
	pg_dump --dbname=accounting_db --host=127.0.0.1 --port=5432 --username=pguser > $(file)

.PHONY: restore-bd
restore-bd:
	psql --dbname=accounting_db --host=127.0.0.1 --port=5432 --username=pguser < $(file)
