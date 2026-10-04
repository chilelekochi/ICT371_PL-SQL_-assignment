--scenario 3: STUDENT HOSTEL ROOM ALLOCATION

--QUESTION 1

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    available_bed_spaces INT NOT NULL
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INT NOT NULL,
    allocation_status VARCHAR(20) NOT NULL DEFAULT 'ALLOCATED',

    CONSTRAINT fk_room
        FOREIGN KEY (room_id)
        REFERENCES hostel_rooms(room_id)
);

-- Add at least 3 rooms
INSERT INTO hostel_rooms (room_number, available_bed_spaces)
VALUES
('A101', 4),
('A102', 2),
('A103', 1);

-- Check the rooms
SELECT * FROM hostel_rooms;


 -- QUESTION 2

DO $$
DECLARE
    spaces INT;
BEGIN

    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF spaces = 0 THEN
        RAISE NOTICE 'The room is full.';

    ELSIF spaces = 1 THEN
        RAISE NOTICE 'The room has one space left.';

    ELSE
        RAISE NOTICE 'The room has several spaces available.';

    END IF;

END $$;



- QUESTION 3

-- WHILE: three hostel inspection days
DO $$
DECLARE
    inspection_day INT := 1;
BEGIN

    WHILE inspection_day <= 3 LOOP

        RAISE NOTICE 'Hostel Inspection Day %', inspection_day;

        inspection_day := inspection_day + 1;

    END LOOP;

END $$;


-- Numeric FOR: three room checks
DO $$
BEGIN

    FOR room_check IN 1..3 LOOP

        RAISE NOTICE 'Room Check Number: %', room_check;

    END LOOP;

END $$;

-- QUESTION 4
-- Allocate a bed space to a student

CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    spaces INT;
BEGIN

    -- Get available spaces
    SELECT available_bed_spaces
    INTO spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    -- Check if room exists
    IF spaces IS NULL THEN
        RAISE NOTICE 'Room does not exist.';

    -- Check if room is full
    ELSIF spaces <= 0 THEN
        RAISE NOTICE 'The room is full.';

    ELSE
        -- Reduce available spaces
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces - 1
        WHERE room_id = p_room_id;

        -- Record the allocation
        INSERT INTO allocations
        (student_number, room_id, allocation_status)
        VALUES
        (p_student_number, p_room_id, 'ALLOCATED');

        RAISE NOTICE 'Room allocated successfully.';

    END IF;

END;
$$;

 QUESTION 5

-- Valid allocation 1
CALL allocate_room('202600001', 1);

-- Valid allocation 2
CALL allocate_room('202600002', 2);

-- Make room 3 full first
CALL allocate_room('202600003', 3);

-- Try another allocation to the full room
CALL allocate_room('202600004', 3);

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;


-- QUESTION 6

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_room_id INT;
    current_status VARCHAR;
BEGIN

    -- Find the allocation
    SELECT room_id, allocation_status
    INTO selected_room_id, current_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    -- Check if allocation exists
    IF selected_room_id IS NULL THEN
        RAISE NOTICE 'Allocation does not exist.';

    -- Check if already completed
    ELSIF current_status = 'COMPLETED' THEN
        RAISE NOTICE 'This student has already checked out.';

    ELSE
        -- Release the bed space
        UPDATE hostel_rooms
        SET available_bed_spaces = available_bed_spaces + 1
        WHERE room_id = selected_room_id;

        -- Mark allocation as completed
        UPDATE allocations
        SET allocation_status = 'COMPLETED'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';

    END IF;

END;
$$;


-- Check out allocation 1
CALL check_out(1);

CALL check_out(1);

-- Check results
SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


-- QUESTION 7

DO $$
DECLARE
    room_record RECORD;

    room_cursor CURSOR FOR
        SELECT room_id, room_number, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

BEGIN

    OPEN room_cursor;

    LOOP

        FETCH room_cursor INTO room_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Room ID: %, Room Number: %, Available Spaces: %',
        room_record.room_id,
        room_record.room_number,
        room_record.available_bed_spaces;

    END LOOP;

    CLOSE room_cursor;

END $$;

-- QUESTION 8

DO $$
DECLARE
    student_number_input VARCHAR := '';
BEGIN

    IF TRIM(student_number_input) = '' THEN
        RAISE EXCEPTION 'Invalid student number. Student number cannot be blank.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;

END $$;

SELECT*FROM hostel_rooms;
SELECT*FROM allocations;
