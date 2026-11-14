# School ERP — MySQL 8.4 + Redis Stack

Database-first School ERP for the PES DBMS Level 3 project.

## Architecture
- Primary relational database (~80%): MySQL 8.4. All authoritative school records and assessed relational DBMS concepts live here.
- Secondary database (~20%): Redis Stack for JSON notice/resource documents and vector retrieval.
- Frontend/backend: Next.js + TypeScript (to be implemented in the next stage).

The 11 ER entities are TEACHER, CLASS, STUDENT, SUBJECT, CLASS_SUBJECT, ATTENDANCE, EXAM, EXAM_RESULT, FEE_PAYMENT, NOTICE and APP_USER.

## MySQL setup (Windows PowerShell)
Install MySQL Server 8.4 and the MySQL command-line client. PostgreSQL is not used by this project.

Create the database in MySQL Workbench or run:

    mysql -u root -p -e "CREATE DATABASE school_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;"

Execute scripts in this order:

    mysql -u root -p school_erp < database/schema.sql
    mysql -u root -p school_erp < database/seed.sql
    mysql -u root -p school_erp < database/functions.sql
    mysql -u root -p school_erp < database/procedures.sql
    mysql -u root -p school_erp < database/triggers.sql
    mysql -u root -p school_erp < database/views.sql
    mysql -u root -p school_erp < database/queries.sql
    mysql -u root -p school_erp < database/tests.sql

Run database/roles.sql separately as root after changing its example password.

## Redis Stack
See redis/README.md. Redis is a secondary document/vector store, not the source of truth.

## Status
The repository is being rebuilt in stages. The SQL foundation is first. Do not treat the Next.js application, authentication, full Redis integration or final validation as complete until their implementations and local test evidence are added.
