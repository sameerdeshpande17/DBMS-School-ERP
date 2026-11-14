USE school_erp;

-- Read-only verification suite: does not insert, update or delete application records.
SELECT 'MYSQL_VERSION' AS check_name, VERSION() AS result;

SELECT 'TABLE_COUNT' AS check_name, COUNT(*) AS result
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';

SELECT 'EXPECTED_TABLES' AS check_name, table_name AS result
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name IN ('teacher','class','student','subject','class_subject','attendance','exam','exam_result','fee_payment','notice','app_user')
ORDER BY table_name;

SELECT 'VIEWS' AS check_name, table_name AS result
FROM information_schema.views
WHERE table_schema = DATABASE()
  AND table_name IN ('vw_student_academic_summary','vw_fee_summary')
ORDER BY table_name;

SELECT 'STORED_PROCEDURES' AS check_name, routine_name AS result
FROM information_schema.routines
WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE'
  AND routine_name = 'sp_mark_attendance';

SELECT 'STORED_FUNCTIONS' AS check_name, routine_name AS result
FROM information_schema.routines
WHERE routine_schema = DATABASE() AND routine_type = 'FUNCTION'
  AND routine_name IN ('fn_attendance_percentage','fn_total_fees_paid')
ORDER BY routine_name;

SELECT 'TRIGGERS' AS check_name, trigger_name AS result
FROM information_schema.triggers
WHERE trigger_schema = DATABASE()
  AND trigger_name IN ('trg_exam_result_validate_insert','trg_exam_result_validate_update','trg_exam_max_marks_update')
ORDER BY trigger_name;

-- Confirm relational data and view execution.
SELECT 'SEED_COUNTS' AS check_name,
       (SELECT COUNT(*) FROM teacher) AS teachers,
       (SELECT COUNT(*) FROM class) AS classes,
       (SELECT COUNT(*) FROM student) AS students,
       (SELECT COUNT(*) FROM subject) AS subjects,
       (SELECT COUNT(*) FROM class_subject) AS class_subject_assignments;

SELECT 'ACADEMIC_VIEW' AS check_name, COUNT(*) AS result
FROM vw_student_academic_summary;

SELECT 'FEE_VIEW' AS check_name, COUNT(*) AS result
FROM vw_fee_summary;

-- Exercise both stored functions without modifying data.
SELECT 'FUNCTIONS' AS check_name,
       fn_attendance_percentage(student_id) AS attendance_percentage,
       fn_total_fees_paid(student_id) AS total_fees_paid
FROM student
ORDER BY student_id
LIMIT 10;

-- Exercise JOIN, nested/correlated subquery, and recursive CTE syntax.
SELECT 'JOIN_QUERY' AS check_name, COUNT(*) AS result
FROM student s JOIN class c ON c.class_id = s.class_id
LEFT JOIN attendance a ON a.student_id = s.student_id;

SELECT 'NESTED_QUERY' AS check_name, COUNT(*) AS result
FROM student WHERE class_id IN (SELECT class_id FROM class_subject);

WITH RECURSIVE levels(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM levels WHERE n < 10
)
SELECT 'RECURSIVE_CTE' AS check_name, COUNT(*) AS result FROM levels;

-- Constraint metadata: all expected core foreign-key relationships.
SELECT 'FOREIGN_KEY_COUNT' AS check_name, COUNT(*) AS result
FROM information_schema.key_column_usage
WHERE table_schema = DATABASE()
  AND referenced_table_name IS NOT NULL;
