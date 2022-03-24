--tested
CREATE OR REPLACE FUNCTION update_grade_in_transcript_table()
  RETURNS TRIGGER
  LANGUAGE plpgsql AS
$$
DECLARE
  course_offering_table_name VARCHAR(50);
  first_idx INT;
  course_offering_identifier INT;
BEGIN
    course_offering_table_name := TG_TABLE_NAME;
    first_idx := position('_' in course_offering_table_name);
    course_offering_identifier := CAST (substring(course_offering_table_name from (first_idx + 1) for length(course_offering_table_name) - first_idx) AS INTEGER);
    
    EXECUTE format(
      'UPDATE %I 
      SET grade = %L
      WHERE course_offering_id = %L', 'transcript_' || NEW.student_id, NEW.grade, course_offering_identifier);
      
    RETURN NEW;
END
$$;

EXECUTE format('
      DROP TRIGGER IF EXISTS trig_update_in_course_offering
      ON %I', 'registrations_' || NEW.course_offering_id);

    EXECUTE format('
      CREATE TRIGGER trig_update_in_course_offering
      AFTER UPDATE
      ON %I
      FOR EACH ROW
      EXECUTE PROCEDURE update_grade_in_transcript_table()', 'registrations_' || NEW.course_offering_id);

--tested
CREATE OR REPLACE FUNCTION add_entry_in_student_transcript_table()
  RETURNS TRIGGER
  LANGUAGE plpgsql AS
$$
DECLARE
  student_table_name VARCHAR(50);
  first_idx INT;
  student_identifier VARCHAR(50);
BEGIN
    student_table_name := TG_TABLE_NAME;
    first_idx := position('_' in student_table_name);
    student_identifier := substring(student_table_name from first_idx + 1 for length(student_table_name) - first_idx);
    
    EXECUTE format(
      'INSERT INTO %I
      (course_offering_id, grade)
      VALUES
      (%L, %L)', 'transcript_' || student_identifier, NEW.course_offering_id, '');
    
    RETURN NEW;
END
$$;

--tested
CREATE OR REPLACE FUNCTION add_entry_in_fa_tickets()
  RETURNS TRIGGER
  LANGUAGE plpgsql AS
$$
DECLARE
  student_table_name VARCHAR(50);
  first_idx INT;
  student_identifier VARCHAR(50);
  batch_identifier INT;
  fa_identifier VARCHAR(50);
BEGIN
    student_table_name := TG_TABLE_NAME;
    first_idx := position('_' in student_table_name);
    student_identifier := substring(student_table_name from first_idx + 1 for length(student_table_name) - first_idx);
    
    SELECT students.batch_id INTO batch_identifier FROM students WHERE students.student_id = student_identifier;
    
    SELECT faculty_advisor.faculty_id INTO fa_identifier FROM faculty_advisor WHERE faculty_advisor.batch_id = batch_identifier;
    EXECUTE format(
      'INSERT INTO %I
      (course_offering_id, status)
      VALUES
      (%s, %L, 0)', 'tickets_' || fa_identifier, NEW.course_offering_id, student_identifier);

    EXECUTE format(
      'INSERT INTO %I
      (course_offering_id, student_id, status)
      VALUES
      (%s, %L, 0)', 'tickets_' || fa_identifier, NEW.course_offering_id, student_identifier);
      
    RETURN NEW;
END
$$;

query := 'select course_offering_id, student_id from $1';

    open prev_tickets for execute query using ('tickets_' || current_user);

  -- req_batch_ids cursor for
  --                 select fa.batch_id
  --                 from faculty_advisor fa
  --                 where fa.faculty_id = current_user;

  -- cur_students  cursor for 
  --                 select st.student_id
  --                 from students st
  --                 where st.batch_id in req_batch_ids;



  EXECUTE format('
      GRANT SELECT
      ON terms
      TO %I', NEW.student_id);
    
    EXECUTE format('
      GRANT SELECT
      ON batches
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON courses
      TO %I', NEW.student_id);
    
    EXECUTE format('
      GRANT SELECT
      ON students
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON faculty
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON faculty_advisor
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON time_slots
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON prerequisites
      TO %I', NEW.student_id);
    
    EXECUTE format('
      GRANT SELECT
      ON course_offerings
      TO %I', NEW.student_id);

    EXECUTE format('
      GRANT SELECT
      ON teaches
      TO %I', NEW.student_id);
