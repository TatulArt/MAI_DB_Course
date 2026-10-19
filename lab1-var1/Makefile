# Makefile: запуск пайплайна лабораторной одной командой
# Использование: make          (БД -> схема -> данные -> тесты; на пустой БД, без сброса)
#                make rebuild  (то же, но сначала reset: стирает ВСЕ данные, только до migration.sql!)
#                make schema   (отдельные шаги: createdb, reset, schema, data, test)
# Параметры можно переопределить: make DB=mydb DB_USER=me

DB   ?= lab1
DB_USER ?= postgres
HOST ?= localhost
EXPECTED_ERRORS ?= 15

PSQL = psql -U $(DB_USER) -h $(HOST)

.PHONY: all rebuild createdb reset schema data test

all: createdb schema data test

# Пересоздание с нуля. Опасно: удаляет все данные
rebuild: createdb reset schema data test

# Создаёт БД, только если её ещё нет
createdb:
	@$(PSQL) -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$(DB)'" | grep -q 1 \
		|| $(PSQL) -d postgres -c "CREATE DATABASE $(DB)"

# Полностью стирает схему public. Только для разработки, ДО этапа с migration.sql!
reset:
	$(PSQL) -d $(DB) -v ON_ERROR_STOP=1 -q -f reset.sql

schema:
	$(PSQL) -d $(DB) -v ON_ERROR_STOP=1 -f schema.sql

data:
	$(PSQL) -d $(DB) -v ON_ERROR_STOP=1 -f data.sql

# Ошибки в constraints_test.sql ожидаемы, поэтому без ON_ERROR_STOP;
# проверяем, что отклонены ровно все операции
test:
	-$(PSQL) -d $(DB) -f constraints_test.sql > constraints_test.log 2>&1
	@n=$$(grep -c 'ERROR' constraints_test.log); \
	echo "Отклонено операций: $$n (ожидалось $(EXPECTED_ERRORS))"; \
	test "$$n" -eq $(EXPECTED_ERRORS)
