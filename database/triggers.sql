USE school_erp;
DELIMITER $$
CREATE TRIGGER trg_exam_result_validate_insert BEFORE INSERT ON exam_result FOR EACH ROW
BEGIN
 DECLARE v_max DECIMAL(7,2); DECLARE v_exam_class BIGINT UNSIGNED; DECLARE v_student_class BIGINT UNSIGNED;
 SELECT max_marks,class_id INTO v_max,v_exam_class FROM exam WHERE exam_id=NEW.exam_id;
 SELECT class_id INTO v_student_class FROM student WHERE student_id=NEW.student_id;
 IF NEW.marks_obtained>v_max THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Marks exceed exam maximum'; END IF;
 IF v_exam_class<>v_student_class THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Student is not in exam class'; END IF;
END$$
CREATE TRIGGER trg_exam_result_validate_update BEFORE UPDATE ON exam_result FOR EACH ROW
BEGIN
 DECLARE v_max DECIMAL(7,2); DECLARE v_exam_class BIGINT UNSIGNED; DECLARE v_student_class BIGINT UNSIGNED;
 SELECT max_marks,class_id INTO v_max,v_exam_class FROM exam WHERE exam_id=NEW.exam_id;
 SELECT class_id INTO v_student_class FROM student WHERE student_id=NEW.student_id;
 IF NEW.marks_obtained>v_max THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Marks exceed exam maximum'; END IF;
 IF v_exam_class<>v_student_class THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Student is not in exam class'; END IF;
END$$
CREATE TRIGGER trg_exam_max_marks_update BEFORE UPDATE ON exam FOR EACH ROW
BEGIN
 IF EXISTS(SELECT 1 FROM exam_result WHERE exam_id=OLD.exam_id AND marks_obtained>NEW.max_marks) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Maximum marks cannot undercut existing results';
 END IF;
END$$
DELIMITER ;
