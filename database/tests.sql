USE school_erp;
-- Small repeatable trigger test. Uses an isolated exam/result and cleans it up.
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_run_integrity_tests$$
CREATE PROCEDURE sp_run_integrity_tests()
BEGIN
 DECLARE v_student BIGINT UNSIGNED; DECLARE v_class BIGINT UNSIGNED;
 DECLARE v_subject BIGINT UNSIGNED; DECLARE v_exam BIGINT UNSIGNED;
 DECLARE v_rejected INT DEFAULT 0;
 SELECT student_id,class_id INTO v_student,v_class FROM student ORDER BY student_id LIMIT 1;
 SELECT subject_id INTO v_subject FROM subject ORDER BY subject_id LIMIT 1;
 INSERT INTO exam(class_id,subject_id,exam_name,exam_date,max_marks) VALUES(v_class,v_subject,'Integrity Test Exam',CURRENT_DATE,100);
 SET v_exam=LAST_INSERT_ID();
 INSERT INTO exam_result(exam_id,student_id,marks_obtained) VALUES(v_exam,v_student,80);
 SET v_rejected=0;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_rejected=1;
  UPDATE exam_result SET marks_obtained=101 WHERE exam_id=v_exam AND student_id=v_student; END;
 IF v_rejected=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='FAIL: marks above maximum accepted'; END IF;
 SET v_rejected=0;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' SET v_rejected=1;
  UPDATE exam SET max_marks=50 WHERE exam_id=v_exam; END;
 IF v_rejected=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='FAIL: invalid maximum accepted'; END IF;
 SELECT 'PASS: valid exam result accepted' test_result;
 SELECT 'PASS: marks above maximum rejected' test_result;
 SELECT 'PASS: maximum marks cannot undercut existing results' test_result;
 DELETE FROM exam WHERE exam_id=v_exam;
END$$
DELIMITER ;
CALL sp_run_integrity_tests();
DROP PROCEDURE sp_run_integrity_tests;
