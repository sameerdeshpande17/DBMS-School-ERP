USE school_erp;
DROP PROCEDURE IF EXISTS sp_mark_attendance;
DELIMITER $$
CREATE PROCEDURE sp_mark_attendance(IN p_student_id BIGINT UNSIGNED,IN p_date DATE,IN p_status VARCHAR(10),IN p_teacher_id BIGINT UNSIGNED)
BEGIN
 INSERT INTO attendance(student_id,attendance_date,status,marked_by) VALUES(p_student_id,p_date,p_status,p_teacher_id)
 ON DUPLICATE KEY UPDATE status=VALUES(status),marked_by=VALUES(marked_by);
END$$
DELIMITER ;
