DROP VIEW IF EXISTS MARKETING_VIEW;

CREATE VIEW MARKETING_VIEW AS
(SELECT 
    m.name AS campaign,

    -- Volume metrics
    COUNT(DISTINCT c.customer_id) AS customers_per_campaign,
    COUNT(DISTINCT a.application_id) AS applications_per_campaign,

    -- Total spend by campaign
    SUM(m.spend) AS amount_spend_per_campaign,

    -- % of total marketing spend
    ROUND(
        (SUM(m.spend) * 100.0 / NULLIF(SUM(SUM(m.spend)) OVER (), 0))::NUMERIC,
        2
    ) AS percent_of_total_spend,

    -- Total credit approved (only for approved applications)
    SUM(CASE WHEN a.approved = 'TRUE' THEN a.approved_amount ELSE 0 END) AS credit_approved_per_campaign,

    -- % of total credit approved across all campaigns
    ROUND(
        (
            SUM(CASE WHEN a.approved = 'TRUE' THEN a.approved_amount ELSE 0 END) * 100.0 /
            NULLIF(SUM(SUM(CASE WHEN a.approved = 'TRUE' THEN a.approved_amount ELSE 0 END)) OVER (), 0)
        )::NUMERIC,
        2
    ) AS credit_approved_pct_of_total,

    -- Total dollars actually used
    SUM(a.dollars_used) AS credit_used_per_campaign,

    -- % of total dollars used across all campaigns
    ROUND(
        (
            SUM(a.dollars_used) * 100.0 /
            NULLIF(SUM(SUM(a.dollars_used)) OVER (), 0)
        )::NUMERIC,
        2
    ) AS credit_used_pct_of_total,

    -- What % of approved credit was actually used (per campaign)
    ROUND(
        (
            SUM(a.dollars_used) * 100.0 /
            NULLIF(SUM(CASE WHEN a.approved = TRUE THEN a.approved_amount ELSE 0 END), 0)
        )::NUMERIC,
        2
    ) AS credit_utilization_pct,

    -- How many dollars used per $1M of marketing spend
    ROUND(
        (
            (SUM(a.dollars_used) * 1.0) / NULLIF(SUM(m.spend), 0) * 1000000
        )::NUMERIC,
        2
    ) AS spend_utilization_per_million

FROM applications_fact a

-- Join each application to the customer and marketing campaign
JOIN customers_dim c ON a.customer_id = c.customer_id
JOIN marketing_dim m ON m.id = c.campaign

-- Limit to applications that occurred during the campaign's active period
WHERE a.submit_date BETWEEN m.start_date AND m.end_date

-- Group by campaign
GROUP BY m.name);
