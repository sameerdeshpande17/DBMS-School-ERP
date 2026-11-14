USE school_erp;
START TRANSACTION;
INSERT INTO teacher(employee_no,first_name,last_name,email,hire_date) VALUES
('TCH001','Ananya','Rao','ananya.rao@school.test','2020-06-01'),
('TCH002','Rahul','Nair','rahul.nair@school.test','2021-07-15')
ON DUPLICATE KEY UPDATE first_name=VALUES(first_name),last_name=VALUES(last_name);
INSERT INTO class(class_name,section,academic_year,class_teacher_id,room_no)
SELECT '10','A','2026-2027',teacher_id,'A-101' FROM teacher WHERE employee_no='TCH001'
ON DUPLICATE KEY UPDATE class_teacher_id=VALUES(class_teacher_id);
INSERT INTO subject(subject_code,subject_name) VALUES ('MATH10','Mathematics'),('PHY10','Physics'),('ENG10','English')
ON DUPLICATE KEY UPDATE subject_name=VALUES(subject_name);
INSERT INTO student(admission_no,first_name,last_name,date_of_birth,gender,email,class_id,admission_date)
SELECT 'ADM2026001','Aarav','Sharma','2010-04-12','MALE','aarav@school.test',class_id,'2026-06-01'
FROM class WHERE class_name='10' AND section='A' AND academic_year='2026-2027'
ON DUPLICATE KEY UPDATE class_id=VALUES(class_id);
INSERT INTO class_subject(class_id,subject_id,teacher_id,academic_year)
SELECT c.class_id,s.subject_id,t.teacher_id,'2026-2027' FROM class c
JOIN subject s ON s.subject_code IN ('MATH10','PHY10')
JOIN teacher t ON t.employee_no=IF(s.subject_code='MATH10','TCH001','TCH002')
WHERE c.class_name='10' AND c.section='A' AND c.academic_year='2026-2027'
ON DUPLICATE KEY UPDATE teacher_id=VALUES(teacher_id);
COMMIT;
