-- SCENARIO 5: ENGINEERING WORKSHOP TOOL LOANS

-- QUESTION 1

CREATE TABLE tools (
    tool_id SERIAL PRIMARY KEY,
    tool_name VARCHAR(100) NOT NULL,
    available_quantity INT NOT NULL
);

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    tool_id INT NOT NULL,
    quantity INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL DEFAULT 'BORROWED',

    CONSTRAINT fk_tool
        FOREIGN KEY (tool_id)
        REFERENCES tools(tool_id)
);

INSERT INTO tools (tool_name, available_quantity)
VALUES
('Hammer', 10),
('Screwdriver', 8),
('Spanner', 5);

SELECT * FROM tools;


-- QUESTION 2

DO $$
DECLARE
    quantity_available INT;
BEGIN

    SELECT t.available_quantity
    INTO quantity_available
    FROM tools AS t
    WHERE t.tool_id = 1;

    IF quantity_available = 0 THEN
        RAISE NOTICE 'Tool is unavailable.';

    ELSIF quantity_available <= 2 THEN
        RAISE NOTICE 'Tool is low on stock.';

    ELSE
        RAISE NOTICE 'Tool is readily available.';

    END IF;

END $$;

-- QUESTION 3

-- WHILE: three workshop safety reminders
DO $$
DECLARE
    reminder_number INT := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE 'Workshop Safety Reminder %',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;

END $$;

-- Numeric FOR: three tool inspections
DO $$
BEGIN

    FOR inspection_number IN 1..3 LOOP

        RAISE NOTICE 'Tool Inspection Number: %',
            inspection_number;

    END LOOP;

END $$;

-- QUESTION 4
-- Procedure to issue tools

CREATE OR REPLACE PROCEDURE issue_tool(
    p_student_number VARCHAR,
    p_tool_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INT;
BEGIN

    -- Get available quantity
    SELECT t.available_quantity
    INTO available
    FROM tools AS t
    WHERE t.tool_id = p_tool_id;

    -- Check if tool exists
    IF available IS NULL THEN
        RAISE NOTICE 'Tool does not exist.';

    -- Check if enough tools are available
    ELSIF available < p_quantity THEN
        RAISE NOTICE 'Not enough tools available.';

    ELSE
        -- Reduce available quantity
        UPDATE tools
        SET available_quantity = available_quantity - p_quantity
        WHERE tool_id = p_tool_id;

        -- Record the tool loan
        INSERT INTO tool_loans
        (student_number, tool_id, quantity, loan_status)
        VALUES
        (p_student_number, p_tool_id, p_quantity, 'BORROWED');

        RAISE NOTICE 'Tool issued successfully.';

    END IF;
	END;
	$$;
-- QUESTION 5

-- Valid loan 1
CALL issue_tool('202600001', 1, 2);

-- Valid loan 2
CALL issue_tool('202600002', 2, 3);

-- Request exceeding available stock
CALL issue_tool('202600003', 3, 20);

-- Check tools
SELECT * FROM tools;

-- Check tool loans
SELECT * FROM tool_loans;



-- QUESTION 6

CREATE OR REPLACE PROCEDURE return_tool(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_tool_id INT;
    returned_quantity INT;
    current_status VARCHAR;
BEGIN

    -- Find the loan
    SELECT tool_id, quantity, loan_status
    INTO selected_tool_id, returned_quantity, current_status
    FROM tool_loans
    WHERE loan_id = p_loan_id;

    -- Check if loan exists
    IF selected_tool_id IS NULL THEN
        RAISE NOTICE 'Tool loan does not exist.';

    -- Check if already returned
    ELSIF current_status = 'RETURNED' THEN
        RAISE NOTICE 'This tool loan has already been returned.';

    ELSE
        -- Restore tool quantity
        UPDATE tools
        SET available_quantity = available_quantity + returned_quantity
        WHERE tool_id = selected_tool_id;

        -- Mark loan as returned
        UPDATE tool_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Tool returned successfully.';

    END IF;

END;
$$;



-- QUESTION 7

DO $$
DECLARE
    tool_record RECORD;

    tool_cursor CURSOR FOR
        SELECT tool_id, tool_name, available_quantity
        FROM tools
        WHERE available_quantity <= 2;

BEGIN

    OPEN tool_cursor;

    LOOP

        FETCH tool_cursor INTO tool_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Tool ID: %, Name: %, Available Quantity: %',
        tool_record.tool_id,
        tool_record.tool_name,
        tool_record.available_quantity;

    END LOOP;

    CLOSE tool_cursor;

END $$;

-- QUESTION 8

DO $$
DECLARE
    quantity_to_issue INT := 0;
BEGIN

    IF quantity_to_issue <= 0 THEN
        RAISE EXCEPTION
        'Invalid quantity. Quantity must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;

END $$;


-- QUESTION 9

SELECT * FROM tools;

SELECT * FROM tool_loans;


