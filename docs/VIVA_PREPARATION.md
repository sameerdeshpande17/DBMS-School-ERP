# Viva and modification guide

1. CLASS_SUBJECT is an associative entity recording class, subject, teacher and academic year.
2. UNIQUE(student_id,attendance_date) prevents duplicate daily attendance.
3. UNIQUE(exam_id,student_id) allows one result per exam/student.
4. A trigger compares marks_obtained to exam.max_marks.
5. The attendance procedure uses INSERT ON CONFLICT to update the daily record.
6. A correlated subquery refers to the outer student row; see queries.sql.
7. A recursive CTE has an anchor term and recursive term.
8. Redis vector search ranks semantically similar embedding vectors; use real model-generated embeddings, never random placeholders.
9. Modification exercise: add a new attendance status to the CHECK constraint and update seed/test data; explain the migration implications.

Be prepared to explain every file and demonstrate the test plan. Tests are not considered passed until run locally.