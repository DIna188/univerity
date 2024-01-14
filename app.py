import psycopg2
from psycopg2 import sql

# Replace these with your actual database credentials
dbname = 'intro'
user = 'postgres'
password = 'deknoi3004'
host = 'localhost'
port = '5432'

try:
    # Establish a connection to the PostgreSQL database
    with psycopg2.connect(
        dbname=dbname,
        user=user,
        password=password,
        host=host,
        port=port
    ) as connection:
        with connection.cursor() as cursor:
            # ------------------------------------------------------------
            # Create the function
            function_query = """
                CREATE OR REPLACE FUNCTION public.fn_taken_course_status(
                    course_code text,
                    student_code text
                ) RETURNS text LANGUAGE plpgsql AS $$
                DECLARE
                    message text;
                    is_waiting INT;
                BEGIN
                    SELECT COUNT(*) INTO is_waiting
                    FROM waiting_list wl
                    WHERE wl.course_code = fn_taken_course_status.course_code
                    AND wl.student_code = fn_taken_course_status.student_code;

                    CASE
                    WHEN is_waiting = 0 THEN
                        message:= 'registered';
                    ELSE
                        message:= 'waiting';
                    END CASE;
                    RETURN message;
                END;
                $$;
            """
            cursor.execute(function_query)

            # Query to retrieve student information
            query = """
                SELECT s.student_code,
                CONCAT(s.first_name, ' ', s.last_name) AS student_name,
                CONCAT(co.name, ' (', r.course_code, ')') AS course,
                fn_taken_course_status(r.course_code, r.student_code) as register_status
                FROM registered r
                LEFT JOIN courses co ON co.course_code = r.course_code
                LEFT JOIN students s ON s.student_code = r.student_code
                LEFT JOIN taken t ON t.student_code = r.student_code
                LEFT JOIN waiting_list wl ON wl.student_code = r.student_code
                WHERE r.course_code = %s;
            """
            filter_course = 'C-004'  # Replace with the course_code you want to filter
            cursor.execute(query, (filter_course,))

            # Fetch the result in rows
            for row in cursor.fetchall():
                print(row)

except psycopg2.Error as e:
    print("Error: Unable to connect to the database.")
    print(e)
