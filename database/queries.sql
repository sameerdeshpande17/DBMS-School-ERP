USE school_erp;
-- DML transaction demonstration
START TRANSACTION;
INSERT INTO notice(title,body,audience,status) VALUES('DML demonstration','Temporary DML example','ALL','DRAFT');
SET @demo_notice_id=LAST_INSERT_ID();
SELECT notice_id,title,status FROM notice WHERE notice_id=@demo_notice_id;
UPDATE notice SET title='Updated DML demonstration' WHERE notice_id=@demo_notice_id;
DELETE FROM notice WHERE notice_id=@demo_notice_id;
COMMIT;

-- INNER JOIN
SELECT s.admission_no,CONCAT(s.first_name,' ',s.last_name) AS student_name,c.class_name,c.section,c.academic_year
FROM student s INNER JOIN class c ON c.class_id=s.class_id;
-- LEFT JOIN
SELECT s.admission_no,a.attendance_date,a.status FROM student s
LEFT JOIN attendance a ON a.student_id=s.student_id ORDER BY s.admission_no,a.attendance_date;
-- Multi-table JOIN
SELECT c.class_name,c.section,s.subject_name,CONCAT(t.first_name,' ',t.last_name) AS teacher_name
FROM class_subject cs JOIN class c ON c.class_id=cs.class_id
JOIN subject s ON s.subject_id=cs.subject_id JOIN teacher t ON t.teacher_id=cs.teacher_id;
-- Nested subquery
SELECT admission_no,first_name,last_name FROM student WHERE class_id IN (SELECT class_id FROM class_subject);
-- Correlated subquery
SELECT s.admission_no,s.first_name FROM student s
WHERE (SELECT COALESCE(SUM(fp.amount),0) FROM fee_payment fp WHERE fp.student_id=s.student_id)>
      (SELECT COALESCE(AVG(amount),0) FROM fee_payment);
-- CTE attendance summary
WITH attendance_summary AS (
 SELECT student_id,COUNT(*) total_days,SUM(status IN ('PRESENT','LATE')) attended_days
 FROM attendance GROUP BY student_id)
SELECT s.admission_no,COALESCE(a.total_days,0) total_days,COALESCE(a.attended_days,0) attended_days,
 ROUND(100*COALESCE(a.attended_days,0)/NULLIF(a.total_days,0),2) attendance_pct
FROM student s LEFT JOIN attendance_summary a ON a.student_id=s.student_id;
-- Recursive CTE demonstration
WITH RECURSIVE levels(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM levels WHERE n<10)
SELECT n AS class_level FROM levels;
