-- dml.sql: операции изменения данных (задание 1.2)
-- Запуск: psql -U postgres -h localhost -d lab1 -f dml.sql
-- Файл МЕНЯЕТ данные, поэтому запускается один раз после queries.sql на подготовленной БД (make prepare).
-- Без ON_ERROR_STOP: в шаге 4 есть операция, которая должна быть отклонена, и это ожидаемо.
-- Транзакция BEGIN ... COMMIT объединяет связанные команды: либо применяются все, либо ни одна.
\set ref_date '2026-11-02'

-- ============================================================================
-- 1. INSERT: новый клиент, его заказ и связанные записи
-- ============================================================================
\echo
\echo '=== 1. INSERT: клиент Роман Кириллов делает первый заказ ==='
BEGIN;

-- RETURNING id возвращает id, который выдала БД; \gset сохраняет его в переменную psql
INSERT INTO customers (full_name, email, phone, registered_at)
VALUES ('Роман Кириллов', 'r.kirillov@example.com', '+79011110019', '2026-11-02 12:00:00+03')
RETURNING id AS new_customer_id \gset

INSERT INTO orders (customer_id, ordered_at, status)
VALUES (:new_customer_id, '2026-11-02 12:05:00+03', 'new')
RETURNING id AS new_order_id \gset

-- unit_price берём из текущей цены товара: INSERT ... SELECT вставляет результат запроса
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT :new_order_id, id, 1, price FROM products WHERE sku = 'HP-AIR';

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT :new_order_id, id, 3, price FROM products WHERE sku = 'ST-NB-A5';

INSERT INTO order_status_history (order_id, status, changed_at, comment)
VALUES (:new_order_id, 'new', '2026-11-02 12:05:00+03', NULL);

COMMIT;

SELECT c.full_name, o.id AS order_id, o.status, p.name AS product, oi.quantity, oi.unit_price
FROM customers c
JOIN orders o       ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id   = o.id
JOIN products p     ON p.id          = oi.product_id
WHERE c.id = :new_customer_id;

-- ============================================================================
-- 2. UPDATE: изменение состояния существующего заказа
-- ============================================================================
\echo
\echo '=== 2. UPDATE: заказ 29 (Мария Иванова) оплачен наличными, статус new -> paid ==='
-- Три действия образуют одно бизнес-событие, поэтому выполняются в одной транзакции:
-- смена статуса, запись платежа и запись в историю (триггера в БД нет, согласованность на нас).
BEGIN;

UPDATE orders SET status = 'paid' WHERE id = 29;

INSERT INTO payments (order_id, amount, method, paid_at)
SELECT 29, SUM(quantity * unit_price), 'cash', '2026-11-02 11:00:00+03'
FROM order_items
WHERE order_id = 29;

INSERT INTO order_status_history (order_id, status, changed_at, comment)
VALUES (29, 'paid', '2026-11-02 11:00:00+03', 'оплата наличными');

COMMIT;

SELECT o.id, o.status, pay.amount, pay.method
FROM orders o
JOIN payments pay ON pay.order_id = o.id
WHERE o.id = 29;

-- ============================================================================
-- 3. Массовый UPDATE по содержательному условию
-- ============================================================================
\echo
\echo '=== 3. Массовый UPDATE: автоотмена заказов new, не оплаченных более 30 дней ==='
-- Условие: статус new и заказ оформлен раньше, чем за 30 дней до опорной даты.
-- Подходят заказы 21 и 22 (сентябрь); заказы 4, 29 и свежие остаются.
-- UPDATE ... RETURNING отдаёт id изменённых заказов; CTE (WITH) тут же использует их,
-- чтобы записать каждому отмену в историю. Всё одним оператором, поэтому статус и история не разойдутся.
WITH cancelled AS (
    UPDATE orders
    SET status = 'cancelled'
    WHERE status = 'new'
      AND ordered_at < DATE :'ref_date' - 30
    RETURNING id
)
INSERT INTO order_status_history (order_id, status, changed_at, comment)
SELECT id, 'cancelled', (:'ref_date' || ' 10:00:00+03')::timestamptz, 'автоотмена: не оплачен более 30 дней'
FROM cancelled;

SELECT o.id, o.ordered_at::date AS order_date, o.status, h.comment
FROM orders o
JOIN order_status_history h ON h.order_id = o.id AND h.status = 'cancelled'
WHERE h.comment LIKE 'автоотмена%'
ORDER BY o.id;

-- ============================================================================
-- 4. DELETE с учётом ограничений целостности
-- ============================================================================
\echo
\echo '=== 4а. DELETE разрешён: отменённый заказ 11 без платежей ==='
-- У заказа 11 есть позиция и история; внешние ключи order_items и order_status_history
-- объявлены с ON DELETE CASCADE, поэтому они удаляются вместе с заказом.
SELECT (SELECT COUNT(*) FROM order_items          WHERE order_id = 11) AS items_before,
       (SELECT COUNT(*) FROM order_status_history WHERE order_id = 11) AS history_before;

DELETE FROM orders WHERE id = 11;

SELECT (SELECT COUNT(*) FROM orders               WHERE id       = 11) AS order_after,
       (SELECT COUNT(*) FROM order_items          WHERE order_id = 11) AS items_after,
       (SELECT COUNT(*) FROM order_status_history WHERE order_id = 11) AS history_after;

\echo
\echo '=== 4б. DELETE разрешён: клиент 15 без заказов ==='
DELETE FROM customers WHERE id = 15;

\echo
\echo '=== 4в. DELETE ОТКЛОНЁН (ожидаемая ошибка): заказ 1 имеет платёж, у payments стоит ON DELETE RESTRICT ==='
DELETE FROM orders WHERE id = 1;

SELECT COUNT(*) AS order_1_still_exists FROM orders WHERE id = 1;

-- ============================================================================
-- 5. ROLLBACK: отмена ошибочных изменений
-- ============================================================================
\echo
\echo '=== 5. ROLLBACK: ошибочное обнуление цен категории "Электроника" откатывается ==='
SELECT MIN(price) AS min_price, MAX(price) AS max_price
FROM products WHERE category_id = (SELECT id FROM categories WHERE name = 'Электроника');

BEGIN;

UPDATE products
SET price = 0
WHERE category_id = (SELECT id FROM categories WHERE name = 'Электроника');

-- внутри транзакции мы видим результат "ошибки"
SELECT MIN(price) AS min_price_in_tx, MAX(price) AS max_price_in_tx
FROM products WHERE category_id = (SELECT id FROM categories WHERE name = 'Электроника');

ROLLBACK;

-- после ROLLBACK цены такие же, как до BEGIN
SELECT MIN(price) AS min_price_after, MAX(price) AS max_price_after
FROM products WHERE category_id = (SELECT id FROM categories WHERE name = 'Электроника');
