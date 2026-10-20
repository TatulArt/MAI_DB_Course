-- 1) UNIQUE: email уже занят клиентом Иваном Петровым
INSERT INTO customers (full_name, email) VALUES ('Двойник', 'ivan.petrov@example.com');

-- 2) UNIQUE: артикул PH-X10 уже есть у другого товара
INSERT INTO products (category_id, name, sku, price, stock) VALUES (1, 'Смартфон-клон', 'PH-X10', 100.00, 1);

-- 3) CHECK: отрицательная цена товара
INSERT INTO products (category_id, name, sku, price, stock) VALUES (1, 'Бракованный товар', 'BAD-1', -5.00, 1);

-- 4) CHECK: отрицательный остаток на складе (UPDATE существующего товара)
UPDATE products SET stock = -1 WHERE sku = 'HM-KT-02';

-- 5) CHECK: статус заказа вне списка допустимых
INSERT INTO orders (customer_id, status) VALUES (1, 'lost');

-- 6) CHECK: нулевое количество в позиции заказа
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (4, 1, 0, 100.00);

-- 7) CHECK: нулевая сумма платежа
INSERT INTO payments (order_id, amount, method) VALUES (4, 0, 'card');

-- 8) CHECK: недопустимый способ оплаты
INSERT INTO payments (order_id, amount, method) VALUES (4, 100.00, 'bitcoin');

-- 9) NOT NULL: у клиента не указан обязательный email
INSERT INTO customers (full_name, email) VALUES ('Без почты', NULL);

-- 10) FOREIGN KEY: заказ несуществующего клиента
INSERT INTO orders (customer_id) VALUES (999);

-- 11) Составное UNIQUE (order_id, product_id): товар 1 уже есть в заказе 1
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 1, 1, 49990.00);

-- 12) Составное UNIQUE (order_id, changed_at): у заказа 1 уже есть запись об этом моменте
INSERT INTO order_status_history (order_id, status, changed_at) VALUES (1, 'paid', '2026-10-01 10:00:00+03');

-- 13) ON DELETE RESTRICT: товар 1 есть в заказах, удалять нельзя
DELETE FROM products WHERE id = 1;

-- 14) ON DELETE RESTRICT: у клиента 1 есть заказы, удалять нельзя
DELETE FROM customers WHERE id = 1;

-- 15) ON DELETE RESTRICT: у заказа 1 есть платёж, удалить заказ нельзя
DELETE FROM orders WHERE id = 1;
