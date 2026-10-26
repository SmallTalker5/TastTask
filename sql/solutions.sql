-- 1. Простая выборка.
SELECT client_id, full_name, city, registered_at
FROM clients
WHERE city = 'Новосибирск'
  AND registered_at >= DATE '2025-01-01'
  AND registered_at < DATE '2026-01-01'
ORDER BY registered_at, client_id;

-- 2. Агрегация.
SELECT currency, COUNT(*) AS open_accounts_count
FROM accounts
WHERE closed_at IS NULL
GROUP BY currency
ORDER BY currency;

-- 3. JOIN и агрегация.
SELECT c.client_id, c.full_name,
       COALESCE(SUM(t.amount), 0) AS total_incoming
FROM clients AS c
LEFT JOIN accounts AS a ON a.client_id = c.client_id
LEFT JOIN transactions AS t ON t.account_id = a.account_id
                           AND t.tx_type = 'in'
GROUP BY c.client_id
ORDER BY c.client_id;

-- 4. Анти-джойн.
SELECT c.client_id, c.full_name
FROM clients AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM accounts AS a
    WHERE a.client_id = c.client_id
)
ORDER BY c.client_id;

-- 5. HAVING.
SELECT c.client_id, c.full_name, COUNT(*) AS accounts_count
FROM clients AS c
JOIN accounts AS a ON a.client_id = c.client_id
GROUP BY c.client_id, c.full_name
HAVING COUNT(*) > 2
ORDER BY c.client_id;

-- 6. Дубли.
SELECT account_id, tx_date, amount, COUNT(*) AS duplicates_count
FROM transactions
GROUP BY account_id, tx_date, amount
HAVING COUNT(*) > 1
ORDER BY account_id, tx_date, amount;

-- 7. Оконные функции.
WITH total_per_month AS (
    SELECT a.client_id,
           DATE_TRUNC('month', t.tx_date)::date AS month,
           SUM(t.amount) AS total_outgoing
    FROM accounts AS a
    JOIN transactions AS t ON t.account_id = a.account_id
    WHERE t.tx_type = 'out'
    GROUP BY a.client_id, DATE_TRUNC('month', t.tx_date)::date
), ranked AS (
    SELECT client_id, month, total_outgoing,
           ROW_NUMBER() OVER (
               PARTITION BY month
               ORDER BY total_outgoing DESC, client_id
           ) AS rn
    FROM total_per_month
)
SELECT r.month, r.rn, c.client_id, c.full_name, r.total_outgoing
FROM ranked AS r
JOIN clients AS c ON c.client_id = r.client_id
WHERE r.rn <= 3
ORDER BY r.month, r.rn;
