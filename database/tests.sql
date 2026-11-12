-- Database integrity tests. Run after schema.sql, seed.sql and triggers.sql.
-- The entire test is rolled back; no permanent test rows are retained.
BEGIN;
DO $$
DECLARE
  v_student BIGINT;
  v_teacher BIGINT;
  v_class BIGINT;
  v_subject BIGINT;
  v_exam BIGINT;
  v_other_class BIGINT;
  v_other_student BIGINT;
  v_rejected BOOLEAN;
BEGIN
  SELECT student_id,class_id INTO STRICT v_student,v_class
  FROM student WHERE admission_no='ADM2026001';
  SELECT teacher_id INTO STRICT v_teacher
  FROM teacher WHERE email='ananya.rao@school.test';
  SELECT subject_id INTO STRICT v_subject
  FROM subject WHERE subject_code='MATH10';

  -- A matching exam should be created for the seeded class and assigned subject.
  INSERT INTO exam(exam_name,exam_type,class_id,subject_id,exam_date,max_marks)
  VALUES('Automated Integrity Test','Unit Test',v_class,v_subject,'2099-01-10',100)
  RETURNING exam_id INTO v_exam;

  -- Attendance can be recorded once per student per date.
  INSERT INTO attendance(student_id,attendance_date,status,marked_by)
  VALUES(v_student,'2099-01-01','Present',v_teacher);

  v_rejected := FALSE;
  BEGIN
    INSERT INTO attendance(student_id,attendance_date,status,marked_by)
    VALUES(v_student,'2099-01-01','Absent',v_teacher);
  EXCEPTION WHEN unique_violation THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'TEST FAILED: duplicate attendance was accepted';
  END IF;

  -- Valid marks should be accepted.
  INSERT INTO exam_result(exam_id,student_id,marks_obtained)
  VALUES(v_exam,v_student,75);

  -- Marks above the exam maximum must be rejected.
  v_rejected := FALSE;
  BEGIN
    INSERT INTO exam_result(exam_id,student_id,marks_obtained)
    VALUES(v_exam,v_student,101);
  EXCEPTION WHEN raise_exception THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'TEST FAILED: marks above maximum were accepted';
  END IF;

  -- A maximum mark cannot be reduced below an existing result.
  v_rejected := FALSE;
  BEGIN
    UPDATE exam SET max_marks=70 WHERE exam_id=v_exam;
  EXCEPTION WHEN raise_exception THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'TEST FAILED: exam maximum was reduced below existing marks';
  END IF;

  -- A student from another class cannot receive this exam result.
  INSERT INTO class(class_name,section,academic_year,room_number)
  VALUES('9','B','2026-2027','TEST-ROOM')
  RETURNING class_id INTO v_other_class;

  INSERT INTO student(admission_no,first_name,last_name,date_of_birth,gender,class_id)
  VALUES('TEST-OTHER-CLASS','Test','Student','2011-01-01','Other',v_other_class)
  RETURNING student_id INTO v_other_student;

  v_rejected := FALSE;
  BEGIN
    INSERT INTO exam_result(exam_id,student_id,marks_obtained)
    VALUES(v_exam,v_other_student,50);
  EXCEPTION WHEN raise_exception THEN
    v_rejected := TRUE;
  END;
  IF NOT v_rejected THEN
    RAISE EXCEPTION 'TEST FAILED: result for a student outside the exam class was accepted';
  END IF;

  RAISE NOTICE 'PASS: duplicate attendance rejected';
  RAISE NOTICE 'PASS: valid exam result accepted';
  RAISE NOTICE 'PASS: marks above maximum rejected';
  RAISE NOTICE 'PASS: maximum marks cannot undercut existing results';
  RAISE NOTICE 'PASS: student from another class rejected';
END;
$$;
ROLLBACK;
