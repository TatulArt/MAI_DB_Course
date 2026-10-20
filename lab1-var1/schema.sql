-- schema.sql: структура БД интернет-магазина (3НФ)
-- Запуск: psql -U postgres -h localhost -d lab1 -v ON_ERROR_STOP=1 -f schema.sql
-- Имена ограничений: pk_ первичный ключ, uq_ уникальность, chk_ проверка, fk_ внешний ключ

-- Клиенты магазина
CREATE TABLE customers (
    id            INTEGER GENERATED ALWAYS AS IDENTITY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    phone         VARCHAR(20),
    registered_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_customers       PRIMARY KEY (id),
    CONSTRAINT uq_customers_email UNIQUE (email)
);

-- Категории товаров
CREATE TABLE categories (
    id   INTEGER GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    CONSTRAINT pk_categories      PRIMARY KEY (id),
    CONSTRAINT uq_categories_name UNIQUE (name)
);

-- Товары; категорию с товарами удалить нельзя
CREATE TABLE products (
    id          INTEGER GENERATED ALWAYS AS IDENTITY,
    category_id INTEGER       NOT NULL,
    name        VARCHAR(200)  NOT NULL,
    sku         VARCHAR(50)   NOT NULL,
    price       NUMERIC(10,2) NOT NULL,
    stock       INTEGER       NOT NULL DEFAULT 0,
    CONSTRAINT pk_products          PRIMARY KEY (id),
    CONSTRAINT uq_products_sku      UNIQUE (sku),
    CONSTRAINT fk_products_category FOREIGN KEY (category_id)
        REFERENCES categories (id) ON DELETE RESTRICT,
    CONSTRAINT chk_products_price   CHECK (price >= 0),
    CONSTRAINT chk_products_stock   CHECK (stock >= 0)
);

-- Заказы; status хранит текущий статус, история лежит в order_status_history
CREATE TABLE orders (
    id          INTEGER GENERATED ALWAYS AS IDENTITY,
    customer_id INTEGER     NOT NULL,
    ordered_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    status      VARCHAR(20) NOT NULL DEFAULT 'new',
    CONSTRAINT pk_orders          PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers (id) ON DELETE RESTRICT,
    CONSTRAINT chk_orders_status  CHECK (status IN ('new', 'paid', 'shipped', 'delivered', 'cancelled'))
);

-- Позиции заказа (связь многие-ко-многим orders <-> products)
-- unit_price: цена на момент покупки, не дубль products.price
CREATE TABLE order_items (
    id         INTEGER GENERATED ALWAYS AS IDENTITY,
    order_id   INTEGER       NOT NULL,
    product_id INTEGER       NOT NULL,
    quantity   INTEGER       NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_order_items               PRIMARY KEY (id),
    CONSTRAINT uq_order_items_order_product UNIQUE (order_id, product_id),
    CONSTRAINT fk_order_items_order         FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product       FOREIGN KEY (product_id)
        REFERENCES products (id) ON DELETE RESTRICT,
    CONSTRAINT chk_order_items_quantity     CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price   CHECK (unit_price >= 0)
);

-- Оплаты заказов; финансовые записи вместе с заказом не удаляются
CREATE TABLE payments (
    id       INTEGER GENERATED ALWAYS AS IDENTITY,
    order_id INTEGER       NOT NULL,
    amount   NUMERIC(10,2) NOT NULL,
    method   VARCHAR(20)   NOT NULL,
    paid_at  TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_payments        PRIMARY KEY (id),
    CONSTRAINT fk_payments_order  FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE RESTRICT,
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT chk_payments_method CHECK (method IN ('card', 'cash', 'transfer'))
);

-- История смены статусов заказа
CREATE TABLE order_status_history (
    id         INTEGER GENERATED ALWAYS AS IDENTITY,
    order_id   INTEGER     NOT NULL,
    status     VARCHAR(20) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    comment    TEXT,
    CONSTRAINT pk_order_status_history          PRIMARY KEY (id),
    CONSTRAINT uq_order_status_history_order_at UNIQUE (order_id, changed_at),
    CONSTRAINT fk_order_status_history_order    FOREIGN KEY (order_id)
        REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT chk_order_status_history_status  CHECK (status IN ('new', 'paid', 'shipped', 'delivered', 'cancelled'))
);
