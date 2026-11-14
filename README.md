# School ERP — MySQL 8.4 + Redis Stack

Database-first School ERP for the PES DBMS Level 3 project.

## Architecture
- Primary relational database (~80%): MySQL 8.4. All authoritative school records and assessed relational DBMS concepts live here.
- Secondary database (~20%): Redis Stack for JSON notice/resource documents and vector retrieval.
- Frontend/backend: Next.js + TypeScript (implementation is in progress).

The 11 ER entities are TEACHER, CLASS, STUDENT, SUBJECT, CLASS_SUBJECT, ATTENDANCE, EXAM, EXAM_RESULT, FEE_PAYMENT, NOTICE and APP_USER.

## MySQL 8.4 setup (Windows PowerShell)

The current local development setup uses MySQL 8.4 on port 3307. From the repository root, run:

```powershell
.\scripts\setup-database.ps1
```

The script prompts for the MySQL root password once, creates the database if needed, and executes the SQL files in dependency order: schema, seed data, functions, procedures, triggers, views, query demonstrations and integrity tests. It stops on a MySQL error and removes its temporary combined SQL file.

Default connection settings are host `127.0.0.1`, port `3307`, user `root`. Override the port if needed:

```powershell
.\scripts\setup-database.ps1 -Port 3306
```

Verify the result:

```powershell
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root -p -h 127.0.0.1 -P 3307 -e "USE school_erp; SHOW TABLES; SELECT COUNT(*) AS students FROM student; SHOW FULL TABLES WHERE Table_type = 'VIEW';"
```

The setup is designed to be rerunnable: schema creation uses `IF NOT EXISTS`, seed inserts use duplicate-key handling, and functions/procedures/triggers are dropped and recreated. The query demonstration removes its temporary notice within a transaction.

### Database roles

Do not run `database/roles.sql` automatically. First replace `CHANGE_THIS_PASSWORD` with a strong private password, then execute it separately as root:

```powershell
Get-Content .\database\roles.sql -Raw | & "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -u root -p -h 127.0.0.1 -P 3307
```

The roles script creates a local `school_app` account. Keep its password private and update the application's environment configuration to match.

## Redis Stack

See [redis/README.md](redis/README.md). Redis is a secondary document/vector store, not the source of truth. Do not claim semantic search is operational until real embedding generation and retrieval are implemented and tested.

## Project status

The SQL foundation and Next.js scaffold are present. Do not treat authentication, full ERP workflows, full Redis integration or final end-to-end validation as complete until implementation and local test evidence are added.
