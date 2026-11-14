USE school_erp;
CREATE OR REPLACE VIEW vw_student_academic_summary AS
SELECT s.student_id,s.admission_no,s.first_name,s.last_name,c.class_name,c.section,
 COUNT(DISTINCT er.exam_result_id) exams_attempted,ROUND(AVG(er.marks_obtained),2) average_marks
FROM student s JOIN class c ON c.class_id=s.class_id
LEFT JOIN exam_result er ON er.student_id=s.student_id
GROUP BY s.student_id,s.admission_no,s.first_name,s.last_name,c.class_name,c.section;
CREATE OR REPLACE VIEW vw_fee_summary AS
SELECT s.student_id,s.admission_no,
 COALESCE(SUM(CASE WHEN fp.payment_status='PAID' THEN fp.amount ELSE 0 END),0) total_paid
FROM student s LEFT JOIN fee_payment fp ON fp.student_id=s.student_id
GROUP BY s.student_id,s.admission_no;
