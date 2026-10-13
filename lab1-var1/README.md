# Лабораторная работа №1. Интернет-магазин (PostgreSQL)

## Запуск
psql -U postgres -h localhost -c "CREATE DATABASE lab1;"
psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f schema.sql
psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f data.sql
psql -U postgres -h localhost -d lab1 -f constraints_test.sql

## Документы (docs/)
- описание предметной области
- ER-диаграмма
- проектные решения
- обоснование 3НФ
