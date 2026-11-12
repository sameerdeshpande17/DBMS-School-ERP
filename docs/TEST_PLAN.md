# Test plan
| ID | Scenario | Preconditions | Steps | Expected result | Actual | Status |
|---|---|---|---|---|---|---|
| DB-01 | Schema | PostgreSQL | Run schema.sql | 11 tables created | Not run | Pending |
| DB-02 | Duplicate attendance | Student exists | Insert duplicate student/date | Unique violation | Not run | Pending |
| DB-03 | Excess marks | Exam exists | Insert marks above max | Trigger rejects | Not run | Pending |
| AUTH-01 | Bad password | User exists | Login with wrong password | HTTP 401 | Not run | Pending |
| REDIS-01 | JSON CRUD | Redis Stack | Run crud.redis | JSON CRUD works | Not run | Pending |
| WEB-01 | Build | Dependencies installed | npm run build | Build passes | Not run | Pending |