-- STEP 1: Select active plans (savings or investment) and join with their confirmed inflow transactions
SELECT 
    p.id AS plan_id,                 -- Unique plan identifier
    p.owner_id,                      -- ID of the user who owns the plan

    -- STEP 2: Determine the type of plan based on its flags
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
    END AS type,

    -- STEP 3: Get the most recent inflow transaction date per plan
    MAX(s.transaction_date) AS last_transaction_date,

    -- STEP 4: Calculate the number of days since the last transaction
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days

FROM 
    plans_plan p

-- STEP 5: Join only confirmed inflow transactions using LEFT JOIN to preserve plans with no transactions
LEFT JOIN 
    savings_savingsaccount s 
    ON p.id = s.plan_id
    AND s.confirmed_amount > 0  -- Only consider inflow transactions

-- STEP 6: Filter to include only active plans (savings or investment)
WHERE 
    (p.is_regular_savings = 1 OR p.is_a_fund = 1)

-- STEP 7: Group by plan and owner to aggregate transactions
GROUP BY 
    p.id, p.owner_id, p.is_regular_savings, p.is_a_fund

-- STEP 8: Return only plans that are inactive for over 365 days or have never had an inflow
HAVING 
    last_transaction_date IS NULL 
    OR DATEDIFF(CURDATE(), last_transaction_date) > 365

-- STEP 9: Sort results by plan ID
ORDER BY 
    plan_id;
