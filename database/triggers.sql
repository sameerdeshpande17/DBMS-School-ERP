-- Validate result ownership, class membership and exam maximum marks.
CREATE OR REPLACE FUNCTION validate_exam_result_marks()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  exam_max NUMERIC(7,2);
  exam_class BIGINT;
  student_class BIGINT;
  exam_subject BIGINT;
  class_year VARCHAR(9);
BEGIN
  SELECT e.max_marks,e.class_id,e.subject_id,c.academic_year
    INTO exam_max,exam_class,exam_subject,class_year
  FROM exam e JOIN class c ON c.class_id=e.class_id
  WHERE e.exam_id=NEW.exam_id;

  IF exam_max IS NULL THEN
    RAISE EXCEPTION 'Exam % does not exist',NEW.exam_id;
  END IF;

  SELECT class_id INTO student_class
  FROM student WHERE student_id=NEW.student_id;

  IF student_class IS NULL THEN
    RAISE EXCEPTION 'Student % does not exist',NEW.student_id;
  END IF;

  IF student_class <> exam_class THEN
    RAISE EXCEPTION 'Student must belong to the class for this exam';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM class_subject cs
    WHERE cs.class_id=exam_class
      AND cs.subject_id=exam_subject
      AND cs.academic_year=class_year
  ) THEN
    RAISE EXCEPTION 'Exam subject is not assigned to this class for the academic year';
  END IF;

  IF NEW.marks_obtained > exam_max THEN
    RAISE EXCEPTION 'Marks (%) cannot exceed exam maximum (%)',NEW.marks_obtained,exam_max;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_exam_marks ON exam_result;
CREATE TRIGGER trg_validate_exam_marks
BEFORE INSERT OR UPDATE OF exam_id,student_id,marks_obtained
ON exam_result FOR EACH ROW EXECUTE FUNCTION validate_exam_result_marks();

-- Prevent lowering maximum marks below already recorded results.
CREATE OR REPLACE FUNCTION validate_exam_max_marks_update()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM exam_result
    WHERE exam_id=NEW.exam_id AND marks_obtained>NEW.max_marks
  ) THEN
    RAISE EXCEPTION 'New maximum marks cannot be lower than an existing result';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_exam_max_update ON exam;
CREATE TRIGGER trg_validate_exam_max_update
BEFORE UPDATE OF max_marks ON exam
FOR EACH ROW EXECUTE FUNCTION validate_exam_max_marks_update();
