# Makefile ЛР2: подготовка БД и запуск сценариев
# Использование: make           (всё по порядку: prepare -> queries -> dml)
#                make prepare   (БД ЛР1 с нуля + расширение данных)
#                make queries   (запросы частей 2-4, только чтение)
#                make dml       (операции изменения данных; меняет БД, повторный запуск - после make prepare)
# Параметры: make DB=mydb DB_USER=me

DB   ?= lab1
DB_USER ?= postgres
HOST ?= localhost

PSQL = psql -U $(DB_USER) -h $(HOST) -d $(DB)

.PHONY: all prepare extra queries dml

all: prepare queries dml

# Пересоздаёт БД ЛР1 (схема + данные + проверка ограничений), затем добавляет данные ЛР2
prepare:
	$(MAKE) -C ../lab1-var1 rebuild DB=$(DB) DB_USER=$(DB_USER) HOST=$(HOST)
	$(MAKE) extra

extra:
	$(PSQL) -v ON_ERROR_STOP=1 -f data_extra.sql

queries:
	$(PSQL) -v ON_ERROR_STOP=1 -f queries.sql

# Без ON_ERROR_STOP: в сценарии есть одна намеренно отклоняемая операция DELETE
dml:
	$(PSQL) -f dml.sql
