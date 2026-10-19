# Проектные решения

## Типы данных

- **Ключи:** `INTEGER GENERATED ALWAYS AS IDENTITY` — автоинкремент по стандарту SQL, вручную `id` не задать.
- **Деньги:** `NUMERIC(10,2)` — точная арифметика, в отличие от `FLOAT`.
- **Время:** `TIMESTAMPTZ` — момент времени с учётом часового пояса.
- **Строки:** `VARCHAR(n)` для ограниченных значений, `TEXT` для свободного комментария.

## Ограничения

| Вид | Где |
|---|---|
| `UNIQUE` | `customers.email`, `categories.name`, `products.sku` |
| `UNIQUE` составной | `order_items (order_id, product_id)`, `order_status_history (order_id, changed_at)` |
| `CHECK` | `price >= 0`, `stock >= 0`, `quantity > 0`, `unit_price >= 0`, `amount > 0`, список статусов (в `orders` и `order_status_history`), список способов оплаты |
| `NOT NULL` | все обязательные поля; необязательны только `customers.phone` и `order_status_history.comment` |

## Правила ON DELETE

| Связь | Правило | Почему |
|---|---|---|
| `orders` → `order_items` | `CASCADE` | позиции не существуют без заказа |
| `orders` → `order_status_history` | `CASCADE` | история принадлежит заказу |
| `products` → `order_items` | `RESTRICT` | нельзя удалить проданный товар, иначе испортится история заказов |
| `customers` → `orders` | `RESTRICT` | заказы клиента нельзя терять |
| `categories` → `products` | `RESTRICT` | нельзя удалить непустую категорию |
| `orders` → `payments` | `RESTRICT` | финансовые записи не удаляются вместе с заказом |

## Особые решения

- **`order_items.unit_price`** хранит цену на момент покупки: цена в `products` меняется, а сумма старого заказа должна остаться прежней.
- **Статус заказа:** `orders.status` — текущий статус (быстрые выборки), `order_status_history` — полная хронология. Триггера нет, поэтому согласованность поддерживается при записи данных вручную.
- **Оплата частями:** связь заказа с платежами 1 : N.
- Список статусов повторяется в двух `CHECK`. В промышленной системе его выносят в справочник или `ENUM`; для учебной работы оставлено проще.
