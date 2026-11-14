# Technology justification

## MySQL 8.4 — primary relational database (~80%)
MySQL stores authoritative structured school records. The schema uses InnoDB, primary/foreign keys, unique/check constraints, transactions and indexes. SQL deliverables include DML, joins, nested and correlated subqueries, CTEs, recursive CTEs, stored functions, procedures, triggers and views.

## Redis Stack — secondary NoSQL/vector database (~20%)
RedisJSON stores flexible notice/resource documents; RediSearch supports text/tag indexing and vector similarity retrieval. It does not replace relational integrity or become the source of truth.

## Application
Next.js/TypeScript provides the portal and API layer. API routes connect to MySQL for school transactions and Redis for notice/resource retrieval.
