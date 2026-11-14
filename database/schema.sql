-- School ERP relational schema — MySQL 8.4
USE school_erp;

CREATE TABLE IF NOT EXISTS teacher (
 teacher_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 employee_no VARCHAR(20) NOT NULL UNIQUE,
 first_name VARCHAR(60) NOT NULL, last_name VARCHAR(60) NOT NULL,
 email VARCHAR(120) NOT NULL UNIQUE, phone VARCHAR(20), hire_date DATE NOT NULL,
 status ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS class (
 class_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 class_name VARCHAR(30) NOT NULL, section VARCHAR(10) NOT NULL,
 academic_year VARCHAR(9) NOT NULL, class_teacher_id BIGINT UNSIGNED,
 room_no VARCHAR(20), UNIQUE KEY uq_class_section_year(class_name,section,academic_year),
 CONSTRAINT fk_class_teacher FOREIGN KEY(class_teacher_id) REFERENCES teacher(teacher_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS student (
 student_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 admission_no VARCHAR(30) NOT NULL UNIQUE, first_name VARCHAR(60) NOT NULL,
 last_name VARCHAR(60) NOT NULL, date_of_birth DATE NOT NULL,
 gender ENUM('FEMALE','MALE','OTHER','UNDISCLOSED') NOT NULL,
 email VARCHAR(120) UNIQUE, phone VARCHAR(20), address VARCHAR(500),
 class_id BIGINT UNSIGNED NOT NULL, admission_date DATE NOT NULL,
 status ENUM('ACTIVE','INACTIVE','GRADUATED','TRANSFERRED') NOT NULL DEFAULT 'ACTIVE',
 CONSTRAINT fk_student_class FOREIGN KEY(class_id) REFERENCES class(class_id) ON DELETE RESTRICT,
 INDEX idx_student_class(class_id), INDEX idx_student_name(last_name,first_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS subject (
 subject_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 subject_code VARCHAR(20) NOT NULL UNIQUE, subject_name VARCHAR(100) NOT NULL UNIQUE,
 description VARCHAR(500)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS class_subject (
 class_subject_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 class_id BIGINT UNSIGNED NOT NULL, subject_id BIGINT UNSIGNED NOT NULL,
 teacher_id BIGINT UNSIGNED NOT NULL, academic_year VARCHAR(9) NOT NULL,
 UNIQUE KEY uq_class_subject_year(class_id,subject_id,academic_year),
 FOREIGN KEY(class_id) REFERENCES class(class_id) ON DELETE CASCADE,
 FOREIGN KEY(subject_id) REFERENCES subject(subject_id) ON DELETE RESTRICT,
 FOREIGN KEY(teacher_id) REFERENCES teacher(teacher_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS attendance (
 attendance_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 student_id BIGINT UNSIGNED NOT NULL, attendance_date DATE NOT NULL,
 status ENUM('PRESENT','ABSENT','LATE','EXCUSED') NOT NULL,
 marked_by BIGINT UNSIGNED, remarks VARCHAR(255),
 UNIQUE KEY uq_attendance_student_date(student_id,attendance_date),
 FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE,
 FOREIGN KEY(marked_by) REFERENCES teacher(teacher_id) ON DELETE SET NULL,
 INDEX idx_attendance_date_status(attendance_date,status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam (
 exam_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 class_id BIGINT UNSIGNED NOT NULL, subject_id BIGINT UNSIGNED NOT NULL,
 exam_name VARCHAR(100) NOT NULL, exam_date DATE NOT NULL,
 max_marks DECIMAL(7,2) NOT NULL CHECK(max_marks>0),
 FOREIGN KEY(class_id) REFERENCES class(class_id) ON DELETE RESTRICT,
 FOREIGN KEY(subject_id) REFERENCES subject(subject_id) ON DELETE RESTRICT,
 INDEX idx_exam_class_date(class_id,exam_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS exam_result (
 exam_result_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 exam_id BIGINT UNSIGNED NOT NULL, student_id BIGINT UNSIGNED NOT NULL,
 marks_obtained DECIMAL(7,2) NOT NULL CHECK(marks_obtained>=0),
 grade VARCHAR(5), remarks VARCHAR(255),
 UNIQUE KEY uq_exam_student(exam_id,student_id),
 FOREIGN KEY(exam_id) REFERENCES exam(exam_id) ON DELETE CASCADE,
 FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS fee_payment (
 fee_payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 student_id BIGINT UNSIGNED NOT NULL, amount DECIMAL(10,2) NOT NULL CHECK(amount>0),
 payment_date DATE NOT NULL,
 payment_method ENUM('CASH','UPI','CARD','BANK_TRANSFER','CHEQUE') NOT NULL,
 receipt_no VARCHAR(40) NOT NULL UNIQUE,
 payment_status ENUM('PAID','PENDING','REFUNDED') NOT NULL DEFAULT 'PAID',
 FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE RESTRICT,
 INDEX idx_fee_student_date(student_id,payment_date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS notice (
 notice_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 title VARCHAR(180) NOT NULL, body TEXT NOT NULL,
 audience ENUM('ALL','TEACHER','STUDENT','PARENT') NOT NULL DEFAULT 'ALL',
 published_at DATETIME, expires_at DATETIME, created_by BIGINT UNSIGNED,
 status ENUM('DRAFT','PUBLISHED','ARCHIVED') NOT NULL DEFAULT 'DRAFT',
 FOREIGN KEY(created_by) REFERENCES teacher(teacher_id) ON DELETE SET NULL,
 INDEX idx_notice_status_date(status,published_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS app_user (
 user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 username VARCHAR(60) NOT NULL UNIQUE, password_hash VARCHAR(255) NOT NULL,
 role ENUM('ADMIN','TEACHER','STUDENT') NOT NULL,
 teacher_id BIGINT UNSIGNED UNIQUE, student_id BIGINT UNSIGNED UNIQUE,
 is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(teacher_id) REFERENCES teacher(teacher_id) ON DELETE CASCADE,
 FOREIGN KEY(student_id) REFERENCES student(student_id) ON DELETE CASCADE,
 CHECK((role='ADMIN' AND teacher_id IS NULL AND student_id IS NULL) OR
       (role='TEACHER' AND teacher_id IS NOT NULL AND student_id IS NULL) OR
       (role='STUDENT' AND student_id IS NOT NULL AND teacher_id IS NULL))
) ENGINE=InnoDB;
