# Лабораторная работа №1. Интернет-магазин (PostgreSQL)

## Запуск

Требуется PostgreSQL и `make`. Подключение: пользователь `postgres`, хост `localhost`, БД `lab1` (меняется через `DB`, `DB_USER`, `HOST`).

    make            # создать БД (если нет), схема, данные, проверка ограничений
    make rebuild    # то же, но сначала стирает все данные (только до migration.sql!)

Отдельные шаги: `make createdb`, `make reset`, `make schema`, `make data`, `make test`.

`make test` пишет результат в `constraints_test.log` и проверяет, что отклонены все 15 некорректных операций.

Миграция (`make rebuild`):

    psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f migration.sql


# ER-диаграмма

PK — первичный ключ, FK — внешний ключ, UK — уникальное значение.

```mermaid
erDiagram
    customers ||--o{ orders : "размещает"
    categories ||--o{ products : "содержит"
    orders ||--|{ order_items : "состоит из"
    products ||--o{ order_items : "входит в"
    orders ||--o{ payments : "оплачивается"
    orders ||--|{ order_status_history : "имеет историю"

    customers {
        int id PK
        varchar full_name
        varchar email UK
        varchar phone
        timestamptz registered_at
    }
    categories {
        int id PK
        varchar name UK
    }
    products {
        int id PK
        int category_id FK
        varchar name
        varchar sku UK
        numeric price
        int stock
    }
    orders {
        int id PK
        int customer_id FK
        timestamptz ordered_at
        varchar status
    }
    order_items {
        int id PK
        int order_id FK
        int product_id FK
        int quantity
        numeric unit_price
    }
    payments {
        int id PK
        int order_id FK
        numeric amount
        varchar method
        timestamptz paid_at
    }
    order_status_history {
        int id PK
        int order_id FK
        varchar status
        timestamptz changed_at
        text comment
    }
```

## Связи

Все связи «один ко многим»; `orders` ↔ `products` — «многие ко многим» через `order_items`.

| Связь | Кратность |
|---|---|
| `customers` → `orders` | 1 : N |
| `categories` → `products` | 1 : N |
| `orders` → `order_items` | 1 : N |
| `products` → `order_items` | 1 : N |
| `orders` → `payments` | 1 : N |
| `orders` → `order_status_history` | 1 : N |

