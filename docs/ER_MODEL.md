# School ERP ER model

The 11 approved entities are TEACHER, CLASS, STUDENT, SUBJECT, CLASS_SUBJECT, ATTENDANCE, EXAM, EXAM_RESULT, FEE_PAYMENT, NOTICE and APP_USER.

Relationships: a teacher may be class teacher for multiple classes; a class contains many students; CLASS_SUBJECT resolves the many-to-many class/subject relationship and assigns a teacher; a student has many attendance records (unique per student/date); an exam belongs to a class and subject; EXAM_RESULT links students and exams; a student can make multiple fee payments; a teacher may create notices; APP_USER links an ADMIN, TEACHER or STUDENT account to the corresponding record.

See database/schema.sql for the concrete attributes, keys and constraints.
