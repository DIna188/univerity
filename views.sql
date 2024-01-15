-- 1. Basic Information View
DROP VIEW IF EXISTS student_branch_view;

CREATE VIEW student_branch_view AS
    SELECT 
        s.student_code,
        s.first_name,
        s.last_name,
        CONCAT(b.name, ' (', b.branch_code, ')') AS branch,
        CONCAT(d.department_name, ' (', d.department_code, ')') AS department,
        CONCAT(p.program_name, ' (', p.program_code, ')') AS program
    FROM students s
    LEFT JOIN student_branches sb ON s.student_code = sb.student_code
    LEFT JOIN branches b ON b.branch_code = sb.branch_code
    LEFT JOIN departments_relate_programs dp ON sb.program_code = dp.program_code
    INNER JOIN departments d ON dp.department_code = d.department_code
    INNER JOIN programs p ON dp.program_code = p.program_code;

SELECT * FROM student_branch_view;

-- 2. Finished Courses View
DROP VIEW IF EXISTS student_finished_course_view;

CREATE VIEW student_finished_course_view AS
    SELECT 
        s.student_code,
        s.first_name,
        s.last_name,
        c.name AS course_name,
        c.course_code,
        t.grade,
        (SELECT COUNT(*) FROM student_credit_point WHERE taken_id = t.taken_id) AS credit
    FROM taken t
    INNER JOIN students s ON t.student_code = s.student_code
    INNER JOIN courses c ON c.course_code = t.course_code
    WHERE t.grade IS NOT NULL AND t.grade <> 'U';

SELECT * FROM student_finished_course_view;

-- 3. Passed Courses View
DROP VIEW IF EXISTS student_passed_course_view;

CREATE VIEW student_passed_course_view AS
    SELECT
        s.student_code,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        CONCAT(c.name, ' (', c.course_code, ')') AS course,
        (SELECT SUM(point) 
            FROM student_credit_point 
            WHERE taken_id = t.taken_id 
            GROUP BY taken_id
        ) AS total_point
    FROM taken t
    INNER JOIN students s ON t.student_code = s.student_code
    INNER JOIN courses c ON c.course_code = t.course_code
    WHERE c.is_ended = TRUE;

SELECT * FROM student_passed_course_view;

-- 4. Registrations View
CREATE VIEW student_register_status AS
    SELECT 
        s.student_code,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        CONCAT(co.name, ' (', r.course_code, ')') AS course,
        fn_taken_course_status(r.course_code, r.student_code) AS register_status,
        wl.created_date
    FROM registered r
    LEFT JOIN courses co ON co.course_code = r.course_code
    LEFT JOIN students s ON s.student_code = r.student_code
    LEFT JOIN taken t ON t.student_code = r.student_code
    LEFT JOIN waiting_list wl ON wl.student_code = r.student_code;

SELECT * FROM student_register_status;

-- 5. Unread Mandatory Courses View
DROP VIEW IF EXISTS unread_mandatory_courses;

CREATE VIEW unread_mandatory_courses AS
    SELECT  
        s.student_code, 
        s.first_name, 
        s.last_name,
        c.name AS course_name, 
        c.course_code
    FROM students s
    CROSS JOIN courses c
    WHERE NOT EXISTS (
        SELECT 1
        FROM taken ta
        WHERE ta.course_code = c.course_code
        AND ta.student_code = s.student_code
    );

SELECT * FROM unread_mandatory_courses;

-- 6. Course Queue Position View
DROP VIEW IF EXISTS range_in_order_waiting_students;

CREATE VIEW range_in_order_waiting_students AS
    SELECT 
        wl.student_code,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        CONCAT(co.name, ' (', co.course_code, ')') AS course,
        ROW_NUMBER() OVER (PARTITION BY wl.course_code ORDER BY wl.created_date) AS waiting_queue_number,
        wl.created_date
    FROM waiting_list wl
    LEFT JOIN courses co ON co.course_code = wl.course_code
    LEFT JOIN students s ON s.student_code = wl.student_code
    WHERE co.is_opening = TRUE
    ORDER BY wl.course_code, wl.created_date;

SELECT * FROM range_in_order_waiting_students;


