# Лабораторная работа №1. Интернет-магазин (PostgreSQL)

## Запуск

Требуется PostgreSQL и `make`. Подключение: пользователь `postgres`, хост `localhost`, БД `lab1` (меняется через `DB`, `DB_USER`, `HOST`).

    make            # создать БД (если нет), схема, данные, проверка ограничений
    make rebuild    # то же, но сначала стирает все данные (только до migration.sql!)

Отдельные шаги: `make createdb`, `make reset`, `make schema`, `make data`, `make test`.

`make test` пишет результат в `constraints_test.log` и проверяет, что отклонены все 15 некорректных операций.

Миграция (после получения задания от преподавателя; `make rebuild` после неё запускать нельзя):

    psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f migration.sql

## Файлы
- `schema.sql` — структура БД
- `data.sql` — тестовые данные
- `constraints_test.sql` — некорректные операции, отклоняемые ограничениями
- `migration.sql` — изменение структуры по дополнительному требованию
- `reset.sql` — полный сброс схемы (только для разработки)

## Документы (docs/)
- [описание предметной области](docs/01-domain.md)
- [ER-диаграмма](docs/02-er-diagram.md)
- [проектные решения](docs/03-design-decisions.md)
- [обоснование 3НФ](docs/04-3nf.md)
