**Q1 – High-Value Customers with Multiple Products**

**Approach Explanation:**

To find customers who hold both a funded savings plan and a funded investment plan, I first broke the problem into three parts: identifying users with savings plans, identifying users with investment plans, and then taking the intersection. I used CTEs to aggregate deposits per plan type—filtering only positive confirmed_amount—and concatenated first_name and last_name safely with COALESCE. Finally, I joined those CTEs back to produce each user’s count of savings and investment plans, summed their deposits (converted from kobo to naira), and sorted by the highest total.

**Difficulties Encountered & Resolution:**

**Missing Names:** Some users had NULL name parts. I fixed this by wrapping each name field in COALESCE(..., '') before concatenation.

**Duplicate Rows:** Early joins paired every savings record with every investment record, inflating counts. I separated the calculations into CTEs, then joined on owner_id to avoid cross-multiplication.

**Slow Query:** An initial single-query approach timed out. I simplified the logic with CTEs and applied filters (confirmed_amount > 0) early to reduce the data scanned.

**Q2 – Transaction Frequency Analysis

Approach Explanation:**

I calculated each user’s transaction frequency by first grouping their transactions by month ('%Y-%m') and computing a monthly count. Then I averaged those monthly counts per user, handled zero-month cases with NULLIF, and classified users into High (≥10), Medium (3–9), and Low (≤2) frequency tiers. A final grouping aggregated customer counts and overall average rates per category, ordered by business priority.

**Difficulties Encountered & Resolution:**

**Zero Transactions:** Users with no transactions yielded NULL or zero months. I used NULLIF(...,0) and defaulted averages to zero to avoid division errors.

**Cross-Year Calculations:** Ensuring the month count spanned multiple years correctly required grouping by formatted year-month rather than just month.

**Balancing Clarity & Speed:** A purely nested query was fast but hard to follow, so I used a single CTE for clarity without sacrificing performance.


**Q3 – Account Inactivity Alert**

**Approach Explanation:**

To flag plans inactive for over a year, I started from the plans_plan table, filtered for savings or investment flags, and left-joined only inflow transactions (confirmed_amount > 0). I used MAX(transaction_date) to find the last activity per plan and then DATEDIFF(CURDATE(), last_transaction_date) to compute inactivity days. In the HAVING clause, I included plans with either no transactions (NULL) or inactivity exceeding 365 days, then ordered by plan ID.

**Difficulties Encountered & Resolution:**

**Including No-transaction Plans**: A normal inner join would drop plans with zero activity. Switching to a LEFT JOIN ensured they remain in the result set.

**Filtering Inflows Only:** To avoid counting non-deposit events, I moved the confirmed_amount > 0 filter into the join condition.

**NULL Handling:** Plans with never-seen transactions had last_transaction_date = NULL; I explicitly checked for NULL in HAVING to capture them.

**Q4 – Customer Lifetime Value Estimation**

**Approach Explanation:**

I computed each customer’s tenure in months via TIMESTAMPDIFF, defaulting to one month for new users to prevent division by zero. A CTE pre-aggregated each user’s total transactions and average confirmed amount (converted from kobo). In the main query, I applied the Customer Lifetime Value formula (total_transactions/tenure_months)×12×0.001×(avg_confirmed_amount/100) wrapped in ROUND(...,2). A LEFT JOIN kept customers with zero transactions (Customer Lifetime Value = 0), and I ordered by descending Customer Lifetime Value  to highlight top value segments.

**Difficulties Encountered & Resolution:**

**Zero-Tenure Users:** Fresh sign-ups had a tenure of zero months; I substituted GREATEST(1, ...) to avoid division errors.

**Zero Transactions:** Some customers had no activity; using LEFT JOIN plus COALESCE(...,0) ensured they appeared with CLV zero rather than disappearing.

**Unit Conversion:** All amounts are in kobo, so I divided by 100 to get naira and multiplied by 0.001 to reflect the 0.1% profit margin accurately.

