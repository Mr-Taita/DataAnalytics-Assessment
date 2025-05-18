-- Step 1: Select customer information and calculate CLV based on transaction history
SELECT
    u.id AS customer_id,
    
    -- Step 2: Concatenate first and last names safely (handle NULLs)
    CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) AS name,
    
    -- Step 3: Calculate account tenure in months since signup
    -- Replace zero months with 1 to avoid division by zero errors in CLV calculation
    CASE
        WHEN TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) = 0 THEN 1
        ELSE TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())
    END AS tenure_months,
    
    -- Step 4: Count total number of confirmed inflow transactions per customer
    COUNT(s.id) AS total_transactions,
    
    -- Step 5: Calculate estimated Customer Lifetime Value (CLV)
    -- Formula: (total_transactions / tenure_months) * 12 * average_profit_per_transaction
    -- average_profit_per_transaction = 0.1% (0.001) of average transaction value (confirmed_amount)
    -- confirmed_amount is stored in kobo, so divide by 100 to convert to currency
    ROUND(
        CASE
            WHEN COUNT(s.id) = 0 THEN 0  -- No transactions means CLV is zero
            ELSE
                (COUNT(s.id) / 
                 CASE WHEN TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) = 0 THEN 1
                      ELSE TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE())
                 END
                ) * 12 * 0.001 * AVG(s.confirmed_amount) / 100
        END,
        2
    ) AS estimated_clv

FROM
    users_customuser u
    -- Step 6: Left join to include all users, even those with zero transactions
    LEFT JOIN savings_savingsaccount s 
        ON u.id = s.owner_id AND s.confirmed_amount > 0  -- Only count inflow transactions

-- Step 7: Group results by customer to aggregate transaction counts and averages
GROUP BY
    u.id, u.first_name, u.last_name, u.date_joined

-- Step 8: Order results by estimated CLV descending to prioritize high-value customers
ORDER BY
    estimated_clv DESC;
