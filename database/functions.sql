USE school_erp;
DROP FUNCTION IF EXISTS fn_attendance_percentage;
DROP FUNCTION IF EXISTS fn_total_fees_paid;
DELIMITER $$
CREATE FUNCTION fn_attendance_percentage(p_student_id BIGINT UNSIGNED)
RETURNS DECIMAL(5,2) READS SQL DATA
BEGIN
 DECLARE v_total INT DEFAULT 0; DECLARE v_present INT DEFAULT 0;
 SELECT COUNT(*),COALESCE(SUM(status IN ('PRESENT','LATE')),0) INTO v_total,v_present
 FROM attendance WHERE student_id=p_student_id;
 IF v_total=0 THEN RETURN 0.00; END IF;
 RETURN ROUND(v_present*100/v_total,2);
END$$
CREATE FUNCTION fn_total_fees_paid(p_student_id BIGINT UNSIGNED)
RETURNS DECIMAL(12,2) READS SQL DATA
BEGIN
 DECLARE v_total DECIMAL(12,2) DEFAULT 0;
 SELECT COALESCE(SUM(amount),0) INTO v_total FROM fee_payment
 WHERE student_id=p_student_id AND payment_status='PAID';
 RETURN v_total;
END$$
DELIMITER ;
