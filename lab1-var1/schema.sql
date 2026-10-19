-- schema.sql: структура БД интернет-магазина (3НФ)
-- Запуск: psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f schema.sql

-- Клиенты магазина
CREATE TABLE customers (
    id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    registered_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Категории товаров
CREATE TABLE categories (
    id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Товары; категорию с товарами удалить нельзя
CREATE TABLE products (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INTEGER       NOT NULL REFERENCES categories (id) ON DELETE RESTRICT,
    name        VARCHAR(200)  NOT NULL,
    sku         VARCHAR(50)   NOT NULL UNIQUE,
    price       NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock       INTEGER       NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

-- Заказы; status хранит текущий статус, история лежит в order_status_history
CREATE TABLE orders (
    id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER     NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    ordered_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    status      VARCHAR(20) NOT NULL DEFAULT 'new'
                CHECK (status IN ('new', 'paid', 'shipped', 'delivered', 'cancelled'))
);

-- Позиции заказа (связь многие-ко-многим orders <-> products)
-- unit_price: цена на момент покупки, не дубль products.price
CREATE TABLE order_items (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   INTEGER       NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id INTEGER       NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)
);

-- Оплаты заказов; финансовые записи вместе с заказом не удаляются
CREATE TABLE payments (
    id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER       NOT NULL REFERENCES orders (id) ON DELETE RESTRICT,
    amount   NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    method   VARCHAR(20)   NOT NULL CHECK (method IN ('card', 'cash', 'transfer')),
    paid_at  TIMESTAMPTZ   NOT NULL DEFAULT now()
);

-- История смены статусов заказа
CREATE TABLE order_status_history (
    id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id   INTEGER     NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    status     VARCHAR(20) NOT NULL
               CHECK (status IN ('new', 'paid', 'shipped', 'delivered', 'cancelled')),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    comment    TEXT,
    UNIQUE (order_id, changed_at)
);
