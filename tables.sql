-- ##########################################################
-- 1. **basic_information(idnr, name, program, branch):**
--    - Displays information about all students. Branch is allowed to be NULL.
DROP VIEW IF EXISTS student_branch_view;

CREATE VIEW student_branch_view AS
    SELECT 
        s.student_code,
        s.first_name,
        s.last_name,
        CONCAT(b.name,' (', b.branch_code, ')') AS branch,
        CONCAT(d.department_name,' (', d.department_code, ')') AS department,
        CONCAT(p.program_name,' (', p.program_code, ')') AS program
        FROM students s
        LEFT JOIN student_branches sb ON s.student_code = sb.student_code
        LEFT JOIN branches b ON b.branch_code = sb.branch_code
        LEFT JOIN departments_relate_programs dp ON sb.program_code = dp.program_code
        INNER JOIN departments d ON dp.department_code = d.department_code
        INNER JOIN programs p ON dp.program_code = p.program_code;

SELECT * FROM student_branch_view;

-- ##########################################################
-- 2. **finished_courses(student, course, grade, credits):**
--    - All completed courses for each student, along with grades and credit points.
DROP VIEW IF EXISTS student_finished_course_view;

CREATE VIEW student_finished_course_view AS
    SELECT s.student_code, s.first_name, s.last_name,
        c.name as course_name, c.course_code, t.grade,
        (SELECT COUNT(*) FROM student_credit_point WHERE taken_id = t.taken_id) AS credit
    FROM taken t
        INNER JOIN students s ON t.student_code = s.student_code
        INNER JOIN courses c ON  c.course_code = t.course_code
        WHERE t.grade IS NOT NULL AND t.grade <> 'U';

SELECT * FROM student_finished_course_view;

-- 3. **passed_courses(student, course, credits):**
--    - All passed courses for each student.
DROP VIEW IF EXISTS student_passed_course_view;

CREATE VIEW student_passed_course_view AS
    SELECT
        s.student_code,
        CONCAT(s.first_name ,' ', s.last_name) AS student_name,
        CONCAT(c.name,' (', c.course_code, ')') AS course,
        (SELECT SUM(point) 
            FROM student_credit_point 
            WHERE taken_id = t.taken_id 
            GROUP BY taken_id
            ) as total_point
        FROM taken t
        INNER JOIN students s ON t.student_code = s.student_code
        INNER JOIN courses c ON  c.course_code = t.course_code
        WHERE c.is_ended = TRUE;
        

SELECT * FROM student_passed_course_view;

-- 4. **registrations(student, course, status):**
--    - All registered and waiting students for different courses. The status can be either 'waiting' or 'registered'.
-- create view
CREATE VIEW IF NOT EXISTS student_register_status AS
    SELECT s.student_code,
    CONCAT(s.first_name ,' ', s.last_name) AS student_name,
    CONCAT(co.name,' (', r.course_code, ')') AS course,
    fn_taken_course_status(r.course_code,r.student_code) as register_status,
    wl.created_date
    FROM registered r
    LEFT JOIN courses co ON co.course_code = r.course_code
    LEFT JOIN students s ON s.student_code = r.student_code
    LEFT JOIN taken t ON t.student_code = r.student_code
    LEFT JOIN waiting_list wl ON wl.student_code = r.student_code;

SELECT * FROM student_register_status;

-- ##########################################################
-- 5. **unread_mandatory(student, course):**
--    - Unread mandatory courses for each student.
-- Create a view for unread mandatory courses
DROP VIEW IF EXISTS unread_mandatory_courses;

CREATE VIEW unread_mandatory_courses AS
    SELECT  s.student_code, s.first_name, s.last_name,
        c.name as course_name, c.course_code
    FROM taken t
    INNER JOIN courses c ON c.course_code = t.course_code
    INNER JOIN mandatory_branch mb ON mb.course_code = c.course_code
    LEFT JOIN students s ON s.student_code = t.student_code
    -- WHERE
    --     NOT EXISTS (
    --         SELECT 1
    --         FROM taken ta
    --         WHERE ta.course_code = t.course_code
    --         AND ta.student_code = t.student_code
    --     );
SELECT * FROM unread_mandatory_courses;

-- ##########################################################
-- 6. **course_queue_position(course, student, place):**
--    - All waiting students, ranked in order on the waiting list.  
DROP VIEW IF EXISTS range_in_order_waiting_students;

CREATE VIEW range_in_order_waiting_students AS
    SELECT wl.student_code,
        CONCAT(s.first_name ,' ', s.last_name) AS student_name,
        CONCAT(co.name,' (', co.course_code, ')') AS course,
        ROW_NUMBER() OVER (PARTITION BY wl.course_code ORDER BY wl.created_date) AS waiting_queue_number,
        wl.created_date
    FROM waiting_list wl
    LEFT JOIN courses co ON co.course_code = wl.course_code
    LEFT JOIN students s ON s.student_code = wl.student_code
    WHERE co.is_opening = TRUE -- only opening registred comment out if you want to show all
    ORDER BY wl.course_code,wl.created_date;

SELECT * FROM range_in_order_waiting_students;

-- Add indexes for foreign key columns
CREATE INDEX IF NOT EXISTS idx_program_code ON departments_relate_programs(program_code);
CREATE INDEX IF NOT EXISTS idx_program_code_branch ON branches(program_code);
CREATE INDEX IF NOT EXISTS idx_department_code_courses ON courses(department_code);
CREATE INDEX IF NOT EXISTS idx_course_code_limited_courses ON limited_courses(course_code);
CREATE INDEX IF NOT EXISTS idx_program_code_student_branches ON student_branches(program_code);
CREATE INDEX IF NOT EXISTS idx_branch_code_student_branches ON student_branches(branch_code);
CREATE INDEX IF NOT EXISTS idx_course_code_classified ON classified(course_code);
CREATE INDEX IF NOT EXISTS idx_program_code_mandatory_program ON mandatory_program(program_code);
CREATE INDEX IF NOT EXISTS idx_course_code_mandatory_program ON mandatory_program(course_code);
CREATE INDEX IF NOT EXISTS idx_program_code_branch_mandatory_branch ON mandatory_branch(program_code, branch_code);
CREATE INDEX IF NOT EXISTS idx_course_code_mandatory_branch ON mandatory_branch(course_code);
CREATE INDEX IF NOT EXISTS idx_program_code_branch_recommended_branch ON recommended_branch(program_code, branch_code);
CREATE INDEX IF NOT EXISTS idx_course_code_recommended_branch ON recommended_branch(course_code);
CREATE INDEX IF NOT EXISTS idx_program_code_students ON students(program_code);
CREATE INDEX IF NOT EXISTS idx_course_code_registered ON registered(course_code);
CREATE INDEX IF NOT EXISTS idx_course_code_taken ON taken(course_code);
CREATE INDEX IF NOT EXISTS idx_student_code_taken ON taken(student_code);
CREATE INDEX IF NOT EXISTS idx_taken_id_student_credit_point ON student_credit_point(taken_id);
CREATE INDEX IF NOT EXISTS idx_course_code_prerequisites ON course_prerequisites(course_code);
CREATE INDEX IF NOT EXISTS idx_prerequisites_course_prerequisites ON course_prerequisites(prerequisites_course);
CREATE INDEX IF NOT EXISTS idx_course_code_waiting_list ON waiting_list(course_code);
CREATE INDEX IF NOT EXISTS idx_student_code_waiting_list ON waiting_list(student_code);
