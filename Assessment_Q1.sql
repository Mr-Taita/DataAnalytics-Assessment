WITH
-- Savings plans funded by user: deposits linked to savings plans
user_savings AS (
    SELECT
        s.owner_id,
        s.plan_id,
        SUM(s.confirmed_amount) AS total_savings_deposit
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id
    WHERE p.is_regular_savings = 1
    GROUP BY s.owner_id, s.plan_id
),

-- Investment plans funded by user: deposits linked to investment plans
user_investments AS (
    SELECT
        s.owner_id,
        s.plan_id,
        SUM(s.confirmed_amount) AS total_investment_deposit
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id
    WHERE p.is_a_fund = 1
    GROUP BY s.owner_id, s.plan_id
),

-- Customers who have at least one savings plan and at least one investment plan
customers_with_both AS (
    SELECT
        u.id AS owner_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name
    FROM users_customuser u
    WHERE u.id IN (SELECT DISTINCT owner_id FROM user_savings)
      AND u.id IN (SELECT DISTINCT owner_id FROM user_investments)
)

SELECT
    c.owner_id,
    c.name,
    COUNT(DISTINCT us.plan_id) AS savings_count,
    COUNT(DISTINCT ui.plan_id) AS investment_count,
    -- sum all deposits across savings and investment plans (kobo to base currency e.g. divide by 100)
    (COALESCE(SUM(us.total_savings_deposit),0) + COALESCE(SUM(ui.total_investment_deposit),0)) / 100.0 AS total_deposits
FROM customers_with_both c
LEFT JOIN user_savings us ON c.owner_id = us.owner_id
LEFT JOIN user_investments ui ON c.owner_id = ui.owner_id
GROUP BY c.owner_id, c.name
ORDER BY total_deposits DESC;
