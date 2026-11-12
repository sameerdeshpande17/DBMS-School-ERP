# School ERP
PES University DBMS Experiential Learning Level 3 mini-project.

## Technology
PostgreSQL, Redis Stack (RedisJSON/RediSearch), Next.js, TypeScript, pg, ioredis, bcryptjs and signed HTTP-only cookie sessions.

## Relational design
The SQL schema maps the 11 entities in the revised ER diagram. It includes keys, foreign keys, CHECK/UNIQUE constraints, indexes, sample data, DML, joins, nested and correlated queries, CTEs, a recursive CTE, functions, procedure, trigger and view. See database/.

## Setup (Windows PowerShell)
1. git clone https://github.com/sameerdeshpande17/DBMS-School-ERP.git
2. cd DBMS-School-ERP
3. Copy-Item .env.example .env.local and set local secrets.
4. psql -U postgres -c "CREATE DATABASE school_erp;"
5. psql -U postgres -d school_erp -f database/schema.sql
6. Run database/functions.sql, procedures.sql, triggers.sql, views.sql and seed.sql with psql -U postgres -d school_erp -f database/FILE.sql.
7. npm install; npm run dev.
8. Start Redis Stack and run redis-cli -h localhost -p 6379 < redis/schema.redis.

## Current implementation boundaries — read before evaluation
This repository is an initial implementation foundation, not a verified complete submission. The current web app has login, dashboard and student read/create API basics; full teacher, attendance, examinations, fees and notice CRUD pages/APIs are not yet implemented. Create app_user records with bcrypt hashes before login; no default credentials are provided. The Redis index and JSON command examples exist, but actual embedding generation, vector ingestion/KNN API and complete Redis CRUD integration are not implemented. The RLS SQL is a demonstration baseline; it is not yet wired to authenticated app requests and must not be represented as verified database-level isolation. The application database role must be configured and tested separately. All tests are pending until run on the target machine. Never commit credentials.

## SQL demonstrations
Run queries.sql after schema and seed. Functions: attendance_percentage(student_id), student_pending_fees(student_id). Procedure: CALL record_attendance(student_id,date,status,teacher_id,remarks). Trigger rejects exam results above maximum marks. View: student_academic_summary.

## Validation
See docs/TEST_PLAN.md. No build, database, Redis, authorization or end-to-end tests have been executed in this environment. Do not claim completed marks without live demonstrations and evidence.