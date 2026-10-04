-- SCENARIO 4: CAMPUS CLINIC MEDICINE DISPENSING

-- QUESTION 1

CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL
);

CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    medicine_id INT NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DISPENSED',

    CONSTRAINT fk_medicine
        FOREIGN KEY (medicine_id)
        REFERENCES medicines(medicine_id)
);


INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 20),
('Amoxicillin', 15),
('Ibuprofen', 10);

SELECT * FROM medicines;

-- QUESTION 2

DO $$
DECLARE
    stock INT;
BEGIN

    SELECT m.stock_quantity
    INTO stock
    FROM medicines AS m
    WHERE m.medicine_id = 1;

    IF stock = 0 THEN
        RAISE NOTICE 'Medicine is out of stock.';

    ELSIF stock <= 5 THEN
        RAISE NOTICE 'Medicine is low on stock.';

    ELSE
        RAISE NOTICE 'Medicine is sufficiently stocked.';

    END IF;

END $$;

-- QUESTION 3

-- WHILE: three stock review days
DO $$
DECLARE
    review_day INT := 1;
BEGIN

    WHILE review_day <= 3 LOOP

        RAISE NOTICE 'Stock Review Day %', review_day;

        review_day := review_day + 1;

    END LOOP;

END $$;


-- Numeric FOR: three shelf inspections
DO $$
BEGIN

    FOR shelf_number IN 1..3 LOOP

        RAISE NOTICE 'Shelf Inspection Number: %', shelf_number;

    END LOOP;

END $$;


-- QUESTION 4
-- Procedure to dispense medicine

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_student_number VARCHAR,
    p_medicine_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    stock INT;
BEGIN

    -- Get available stock
    SELECT m.stock_quantity
    INTO stock
    FROM medicines AS m
    WHERE m.medicine_id = p_medicine_id;

    -- Check if medicine exists
    IF stock IS NULL THEN
        RAISE NOTICE 'Medicine does not exist.';

    -- Check if enough stock is available
    ELSIF stock < p_quantity THEN
        RAISE NOTICE 'Not enough medicine in stock.';

    ELSE
        -- Reduce stock
        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        -- Record dispensing
        INSERT INTO dispensing_records
        (student_number, medicine_id, quantity, status)
        VALUES
        (p_student_number, p_medicine_id, p_quantity, 'DISPENSED');

        RAISE NOTICE 'Medicine dispensed successfully.';

    END IF;

END;
$$;


-- QUESTION 5

-- Valid dispensing 1
CALL dispense_medicine('202600001', 1, 5);

-- Valid dispensing 2
CALL dispense_medicine('202600002', 2, 3);

-- Quantity exceeding available stock
CALL dispense_medicine('202600003', 3, 50);

SELECT * FROM medicines;


SELECT * FROM dispensing_records;

-- QUESTION 6

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    selected_medicine_id INT;
    dispensed_quantity INT;
    current_status VARCHAR;
BEGIN

    -- Find the dispensing record
    SELECT medicine_id, quantity, status
    INTO selected_medicine_id, dispensed_quantity, current_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;

    -- Check if record exists
    IF selected_medicine_id IS NULL THEN
        RAISE NOTICE 'Dispensing record does not exist.';

    -- Check if already reversed
    ELSIF current_status = 'REVERSED' THEN
        RAISE NOTICE 'This dispensing record has already been reversed.';

    ELSE
        -- Restore medicine stock
        UPDATE medicines
        SET stock_quantity = stock_quantity + dispensed_quantity
        WHERE medicine_id = selected_medicine_id;

        -- Mark record as reversed
        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;

        RAISE NOTICE 'Dispensing successfully reversed.';

    END IF;

END;
$$;


-- Reverse dispensing record 1
CALL reverse_dispensing(1);

-- Try reversing the same record again
CALL reverse_dispensing(1);

-- Check results
SELECT * FROM medicines;
SELECT * FROM dispensing_records;

-- QUESTION 7

DO $$
DECLARE
    medicine_record RECORD;

    medicine_cursor CURSOR FOR
        SELECT medicine_id, medicine_name, stock_quantity
        FROM medicines
        WHERE stock_quantity < 5;

BEGIN

    OPEN medicine_cursor;

    LOOP

        FETCH medicine_cursor INTO medicine_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Medicine ID: %, Name: %, Stock: %',
        medicine_record.medicine_id,
        medicine_record.medicine_name,
        medicine_record.stock_quantity;

    END LOOP;

    CLOSE medicine_cursor;

END $$;

-- QUESTION 8

DO $$
DECLARE
    quantity_to_dispense INT := -5;
BEGIN

    IF quantity_to_dispense < 0 THEN
        RAISE EXCEPTION
        'Invalid quantity. Dispensing quantity cannot be negative.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;

END $$;

-- QUESTION 9

SELECT * FROM medicines;

SELECT * FROM dispensing_records;
