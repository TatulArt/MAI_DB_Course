-- queries.sql: запросы ЛР2 (части 2, 3 и 4). Только чтение, данные не меняются.
-- Запуск: psql -U postgres -h localhost -d lab1 -f queries.sql
-- Требует данные ЛР1 + data_extra.sql (make prepare).
--
-- Опорная дата для всех запросов с "сегодня" - фиксированная, чтобы результат не менялся со временем.
-- Выручка = SUM(quantity * unit_price) по позициям НЕОТМЕНЁННЫХ заказов (отменённый заказ денег не приносит).
\set ref_date '2026-11-02'

-- ============================================================================
-- ЧАСТЬ 2. ОПЕРАЦИОННАЯ ИНФОРМАЦИЯ
-- ============================================================================

\echo
\echo '=== 2.1(а) Подробности: позиции неотменённых заказов с октября (5 таблиц, INNER JOIN) ==='
-- Задача: оператору нужен подробный список "кто, что и в каком заказе купил".
-- INNER JOIN оставляет только строки, для которых нашлась пара во всех таблицах.
SELECT o.id                           AS order_id,
       o.ordered_at::date             AS order_date,
       o.status,
       c.full_name                    AS customer,
       cat.name                       AS category,
       p.name                         AS product,
       oi.quantity,
       oi.unit_price,
       oi.quantity * oi.unit_price    AS line_total
FROM orders o
JOIN customers   c   ON c.id   = o.customer_id
JOIN order_items oi  ON oi.order_id = o.id
JOIN products    p   ON p.id   = oi.product_id
JOIN categories  cat ON cat.id = p.category_id
WHERE o.status <> 'cancelled'
  AND o.ordered_at >= '2026-10-01'
ORDER BY o.id, p.name;

\echo
\echo '=== 2.1(б) Пустоты: категории и товары, которые ни разу не попадали в заказы (LEFT JOIN) ==='
-- Задача: найти "мёртвый" ассортимент. LEFT JOIN сохраняет строку слева, даже если справа пары нет
-- (тогда столбцы справа = NULL). Именно по NULL в oi.id мы и отбираем "пустые" строки.
-- Категория без товаров даёт p.id = NULL, товар без заказов даёт oi.id = NULL.
SELECT cat.name                                  AS category,
       COALESCE(p.name, '(в категории нет товаров)') AS product,
       p.stock,
       p.price
FROM categories cat
LEFT JOIN products    p  ON p.category_id = cat.id
LEFT JOIN order_items oi ON oi.product_id = p.id
WHERE oi.id IS NULL
ORDER BY cat.name, p.name;

\echo
\echo '=== 2.1(в) Несколько условий: доставленные заказы на электронику от 10000 руб., оплаченные картой ==='
-- Задача: отдел продаж выбирает крупные карточные покупки электроники (6 таблиц).
-- Условия связаны: товар из категории, заказ в статусе, платёж определённого вида, сумма позиции.
SELECT DISTINCT
       c.full_name                  AS customer,
       o.id                         AS order_id,
       p.name                       AS product,
       oi.quantity * oi.unit_price  AS line_total,
       pay.method,
       pay.paid_at::date            AS paid_date
FROM customers c
JOIN orders      o   ON o.customer_id = c.id
JOIN order_items oi  ON oi.order_id   = o.id
JOIN products    p   ON p.id          = oi.product_id
JOIN categories  cat ON cat.id        = p.category_id
JOIN payments    pay ON pay.order_id  = o.id
WHERE cat.name = 'Электроника'
  AND o.status = 'delivered'
  AND pay.method = 'card'
  AND oi.quantity * oi.unit_price >= 10000
ORDER BY line_total DESC;

\echo
\echo '=== 2.2(а) Количественные показатели по статусам заказов ==='
-- Задача: сколько заказов, клиентов, штук и денег в каждом статусе. Группа = статус.
SELECT o.status,
       COUNT(DISTINCT o.id)                          AS orders,
       COUNT(DISTINCT o.customer_id)                 AS customers,
       SUM(oi.quantity)                              AS units,
       SUM(oi.quantity * oi.unit_price)              AS amount,
       ROUND(AVG(oi.quantity * oi.unit_price), 2)    AS avg_line,
       MAX(oi.quantity * oi.unit_price)              AS max_line
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
GROUP BY o.status
ORDER BY amount DESC;

\echo
\echo '=== 2.2(б) Клиенты с выручкой больше 20000 и минимум двумя заказами (HAVING) ==='
-- Задача: найти ключевых клиентов. WHERE фильтрует СТРОКИ до группировки (отменённые заказы
-- отбрасываем), HAVING фильтрует ГРУППЫ после неё (по сумме и числу заказов).
SELECT c.full_name                                         AS customer,
       COUNT(DISTINCT o.id)                                AS orders,
       SUM(oi.quantity * oi.unit_price)                    AS revenue,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.id), 2) AS avg_order,
       MIN(o.ordered_at)::date                             AS first_order,
       MAX(o.ordered_at)::date                             AS last_order
FROM customers c
JOIN orders      o  ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id   = o.id
WHERE o.status <> 'cancelled'
GROUP BY c.id, c.full_name
HAVING SUM(oi.quantity * oi.unit_price) > 20000
   AND COUNT(DISTINCT o.id) >= 2
ORDER BY revenue DESC;

\echo
\echo '=== 2.2(в) Сравнение периодов: выручка по категориям и месяцам ==='
-- Задача: как менялись продажи категорий от месяца к месяцу. Приём "условная агрегация":
-- CASE внутри SUM даёт отдельный столбец на каждый месяц, поэтому периоды видны рядом.
SELECT cat.name                                                        AS category,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.ordered_at) = 8  THEN oi.quantity * oi.unit_price ELSE 0.00 END) AS aug,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.ordered_at) = 9  THEN oi.quantity * oi.unit_price ELSE 0.00 END) AS sep,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.ordered_at) = 10 THEN oi.quantity * oi.unit_price ELSE 0.00 END) AS oct,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.ordered_at) = 11 THEN oi.quantity * oi.unit_price ELSE 0.00 END) AS nov,
       SUM(oi.quantity * oi.unit_price)                                AS total,
       COUNT(DISTINCT o.id)                                            AS orders,
       MAX(oi.unit_price)                                              AS max_price
FROM categories cat
JOIN products    p  ON p.category_id = cat.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders      o  ON o.id          = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY cat.id, cat.name
ORDER BY total DESC;

-- ============================================================================
-- ЧАСТЬ 3. ПОДЗАПРОСЫ
-- ============================================================================

\echo
\echo '=== 3.1 Товары дороже средней цены своей категории ==='
-- Задача: найти "премиальные" товары внутри категории. Подзапрос в FROM считает среднюю цену
-- каждой категории один раз; затем каждый товар сравнивается со средней своей категории.
SELECT cat.name                  AS category,
       p.name                    AS product,
       p.price,
       ROUND(ca.avg_price, 2)    AS category_avg
FROM products p
JOIN categories cat ON cat.id = p.category_id
JOIN (SELECT category_id, AVG(price) AS avg_price
      FROM products
      GROUP BY category_id) ca ON ca.category_id = p.category_id
WHERE p.price > ca.avg_price
ORDER BY cat.name, p.price DESC;

\echo
\echo '=== 3.2 EXISTS: клиенты, у которых есть хотя бы один платёж картой от 20000 ==='
-- Задача: список клиентов для премиальной программы. EXISTS отвечает "есть ли хоть одна строка":
-- подробности платежей нас не интересуют, поэтому в подзапросе SELECT 1.
SELECT c.id, c.full_name, c.email
FROM customers c
WHERE EXISTS (SELECT 1
              FROM orders o
              JOIN payments p ON p.order_id = o.id
              WHERE o.customer_id = c.id
                AND p.method = 'card'
                AND p.amount >= 20000)
ORDER BY c.id;

\echo
\echo '=== 3.3 NOT EXISTS: покупавшие клиенты, не делавшие заказов последние 30 дней (отток) ==='
-- Задача: кому напомнить о магазине. Отсутствие заказа за последние 30 дней несёт смысл только для
-- тех, кто покупал раньше, поэтому первое условие - EXISTS (был неотменённый заказ),
-- второе - NOT EXISTS (нет неотменённого заказа с :ref_date минус 30 дней).
SELECT c.id, c.full_name, c.email
FROM customers c
WHERE EXISTS (SELECT 1
              FROM orders o
              WHERE o.customer_id = c.id
                AND o.status <> 'cancelled')
  AND NOT EXISTS (SELECT 1
                  FROM orders o
                  WHERE o.customer_id = c.id
                    AND o.status <> 'cancelled'
                    AND o.ordered_at >= DATE :'ref_date' - 30)
ORDER BY c.id;

\echo
\echo '=== 3.4 Коррелированный подзапрос: индивидуальные показатели каждого клиента ==='
-- Задача: для КАЖДОГО клиента посчитать дату последнего заказа и сумму покупок. Внутренние
-- запросы ссылаются на c.id из внешнего, поэтому выполняются заново для каждой строки customers.
-- У клиентов без заказов дата = NULL, а сумма = 0 благодаря COALESCE.
SELECT c.id,
       c.full_name,
       (SELECT MAX(o.ordered_at)::date
        FROM orders o
        WHERE o.customer_id = c.id
          AND o.status <> 'cancelled')                      AS last_order,
       (SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0.00)
        FROM orders o
        JOIN order_items oi ON oi.order_id = o.id
        WHERE o.customer_id = c.id
          AND o.status <> 'cancelled')                      AS total_spent
FROM customers c
ORDER BY total_spent DESC, c.id;

-- ============================================================================
-- ЧАСТЬ 4. КОМПЛЕКСНЫЙ ОТЧЁТ НА CTE
-- ============================================================================
-- Вопрос руководителя: "Кто приносит основную выручку и как поделена клиентская база на сегменты?"
--
-- Схема вычислений:
--
--  Исходные данные          Промежуточные показатели             Агрегация            Итоговый отчёт
--  orders, order_items  ->  order_totals (сумма каждого      ->  segments (клиент +  -> по сегментам:
--  customers                заказа) -> customer_stats                сегмент по правилам)   число клиентов,
--                           (заказы, выручка, последний заказ                                выручка, доля, список
--                           по каждому клиенту)                                              клиентов
--
-- 1) order_totals. Вход: orders + order_items. Преобразование: отбросить отменённые заказы,
--    сгруппировать позиции по заказу и сложить quantity * unit_price. Результат: одна строка на заказ
--    (номер, клиент, дата, сумма).
-- 2) customer_stats. Вход: customers + order_totals. Преобразование: LEFT JOIN (чтобы клиенты без
--    заказов не пропали), группировка по клиенту: число заказов, выручка, дата последнего заказа.
--    Результат: одна строка на клиента (в том числе с нулями и NULL).
-- 3) segments. Вход: customer_stats. Преобразование: присвоить сегмент через CASE:
--    нет заказов - "Без покупок"; выручка от 50000 - "VIP"; последний заказ раньше, чем 30 дней
--    назад - "Спящие"; остальные - "Активные". Результат: клиент + сегмент.
-- 4) Итог. Вход: segments + общая выручка. Преобразование: группировка по сегменту: число клиентов,
--    заказов, выручка, доля выручки в процентах, перечень клиентов. Результат: 4 строки отчёта.
\echo
\echo '=== 4. Отчёт: сегменты клиентов по выручке и активности ==='
WITH order_totals AS (
    SELECT o.id                              AS order_id,
           o.customer_id,
           o.ordered_at,
           SUM(oi.quantity * oi.unit_price)  AS order_amount
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    WHERE o.status <> 'cancelled'
    GROUP BY o.id, o.customer_id, o.ordered_at
),
customer_stats AS (
    SELECT c.id,
           c.full_name,
           COUNT(ot.order_id)                AS orders_cnt,
           COALESCE(SUM(ot.order_amount), 0.00) AS revenue,
           MAX(ot.ordered_at)                AS last_order
    FROM customers c
    LEFT JOIN order_totals ot ON ot.customer_id = c.id
    GROUP BY c.id, c.full_name
),
segments AS (
    SELECT cs.*,
           CASE
               WHEN cs.orders_cnt = 0                        THEN 'Без покупок'
               WHEN cs.revenue >= 50000                      THEN 'VIP'
               WHEN cs.last_order < DATE :'ref_date' - 30    THEN 'Спящие'
               ELSE 'Активные'
           END AS segment
    FROM customer_stats cs
)
SELECT s.segment,
       COUNT(*)                                                       AS customers,
       SUM(s.orders_cnt)                                              AS orders,
       SUM(s.revenue)                                                 AS revenue,
       ROUND(100.0 * SUM(s.revenue) / (SELECT SUM(revenue) FROM customer_stats), 1) AS revenue_share_pct,
       STRING_AGG(s.full_name, ', ' ORDER BY s.revenue DESC, s.full_name) AS members
FROM segments s
GROUP BY s.segment
ORDER BY revenue DESC;
