# Лабораторная работа №1. Интернет-магазин (PostgreSQL)

## Запуск

Требуется PostgreSQL и `make`. Подключение: пользователь `postgres`, хост `localhost`, БД `lab1` (меняется через `DB`, `DB_USER`, `HOST`).

    make            # создать БД (если нет), схема, данные, проверка ограничений
    make rebuild    # то же, но сначала стирает все данные (только до migration.sql!)

Отдельные шаги: `make createdb`, `make reset`, `make schema`, `make data`, `make test`.

`make test` пишет результат в `constraints_test.log` и проверяет, что отклонены все 15 некорректных операций.

Миграция (`make rebuild`):

    psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f migration.sql


- [ER-диаграмма](docs/er-diagram.md)
