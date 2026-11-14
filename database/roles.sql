-- Run as MySQL root on a local development instance. Change the example password first.
CREATE ROLE IF NOT EXISTS 'school_admin_role','school_teacher_role','school_student_role';
GRANT SELECT,INSERT,UPDATE,DELETE ON school_erp.* TO 'school_admin_role';
GRANT SELECT ON school_erp.student TO 'school_teacher_role';
GRANT SELECT,INSERT,UPDATE ON school_erp.attendance TO 'school_teacher_role';
GRANT SELECT ON school_erp.exam TO 'school_teacher_role';
GRANT SELECT ON school_erp.exam_result TO 'school_teacher_role';
GRANT SELECT ON school_erp.notice TO 'school_teacher_role';
GRANT SELECT ON school_erp.notice TO 'school_student_role';
-- MySQL has no PostgreSQL-style native row-level security. Student-specific row filtering
-- must be implemented in parameterized authenticated application queries/views.
CREATE USER IF NOT EXISTS 'school_app'@'localhost' IDENTIFIED BY 'CHANGE_THIS_PASSWORD';
GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE ON school_erp.* TO 'school_app'@'localhost';
