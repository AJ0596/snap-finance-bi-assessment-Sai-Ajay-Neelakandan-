DROP TABLE IF EXISTS store_metrics_fact;

CREATE TABLE store_metrics_fact as
(SELECT 
    a.store,
    s.industry,
    s.size,
    s.state AS location,

    COUNT(*) AS num_applications,

    COUNT(CASE WHEN a.approved = TRUE THEN 1 END) AS num_approved_applications,
    ROUND(
        COUNT(CASE WHEN a.approved = TRUE THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS approval_rate,

    SUM(CASE WHEN a.approved = TRUE THEN a.approved_amount ELSE 0 END) AS total_approved_amount,
    SUM(CASE WHEN a.approved = TRUE THEN a.dollars_used ELSE 0 END) AS total_used_amount,

    ROUND((
        SUM(CASE WHEN a.approved = TRUE THEN a.dollars_used END) * 100.0
        / NULLIF(SUM(CASE WHEN a.approved = TRUE THEN a.approved_amount END), 0)
    )::NUMERIC, 2) AS percent_used_amount,

    COUNT(CASE WHEN a.approved = TRUE AND a.dollars_used > 0 THEN 1 END) AS num_used_applications

FROM applications_fact a
INNER JOIN stores_dim s ON a.store = s.store

GROUP BY a.store, s.industry, s.size, s.state
ORDER BY a.store);

