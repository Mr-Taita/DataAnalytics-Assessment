WITH
-- Step 1: Get total transactions and first/last transaction dates per customer
user_transactions AS (
    SELECT
        u.id AS owner_id,
        COUNT(s.transaction_date) AS total_transactions,
        MIN(s.transaction_date) AS first_date,
        MAX(s.transaction_date) AS last_date
    FROM users_customuser u
    LEFT JOIN savings_savingsaccount s 
        ON u.id = s.owner_id
    GROUP BY u.id
),

-- Step 2: Calculate how many months each user has been active
user_activity_months AS (
    SELECT
        owner_id,
        total_transactions,
        CASE 
            WHEN total_transactions = 0 THEN 0  -- Handle users with no transactions
            ELSE 
                (YEAR(last_date) - YEAR(first_date)) * 12 
                + (MONTH(last_date) - MONTH(first_date)) 
                + 1
        END AS num_months
    FROM user_transactions
),

-- Step 3: Compute average number of transactions per month per user
user_avg_transactions AS (
    SELECT
        owner_id,
        CASE
            WHEN num_months = 0 THEN 0  -- Avoid division by zero
            ELSE total_transactions / num_months
        END AS avg_tx_per_month
    FROM user_activity_months
),

-- Step 4: Categorize users based on average monthly transaction frequency
user_frequency AS (
    SELECT
        owner_id,
        avg_tx_per_month,
        CASE
            WHEN avg_tx_per_month >= 10 THEN 'High Frequency'
            WHEN avg_tx_per_month >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM user_avg_transactions
)

-- Step 5: Aggregate and summarize users by frequency category
SELECT
    frequency_category,
    COUNT(owner_id) AS customer_count,
    ROUND(AVG(avg_tx_per_month), 1) AS avg_transactions_per_month
FROM user_frequency
GROUP BY frequency_category
ORDER BY 
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        ELSE 3
    END;
