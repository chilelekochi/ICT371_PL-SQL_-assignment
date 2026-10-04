--SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    book_title VARCHAR(100) NOT NULL,
    available_copies INT NOT NULL
);

-- Create book_loans table
CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL DEFAULT 'BORROWED',

    CONSTRAINT fk_book
        FOREIGN KEY (book_id)
        REFERENCES books(book_id)
);
INSERT INTO books (book_title, available_copies)
VALUES
('Database Systems', 5),
('Computer Networks', 3),
('Machine Learning', 2);
SELECT * FROM books;

DO $$
DECLARE
    copies INT;
BEGIN

    SELECT available_copies
    INTO copies
    FROM books
    WHERE book_id = 1;

    IF copies = 0 THEN
        RAISE NOTICE 'The book is unavailable.';

    ELSIF copies <= 2 THEN
        RAISE NOTICE 'The book has low copies.';

    ELSE
        RAISE NOTICE 'The book is sufficiently stocked.';

    END IF;

END $$;

--Q3
-- WHILE loop: three overdue reminders
DO $$
DECLARE
    reminder_number INT := 1;
BEGIN

    WHILE reminder_number <= 3 LOOP

        RAISE NOTICE 'Overdue Reminder %', reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;

END $$;


-- Numeric FOR loop: three library shelf numbers
DO $$
BEGIN

    FOR shelf_number IN 1..3 LOOP

        RAISE NOTICE 'Library Shelf Number: %', shelf_number;

    END LOOP;

END $$;


--QUESTION4
--Procedure to borrow a book

CREATE OR REPLACE PROCEDURE borrow_book(
    p_student_number VARCHAR,
    p_book_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INT;
BEGIN

    -- Check the available copies
    SELECT available_copies
    INTO available
    FROM books
    WHERE book_id = p_book_id;

    -- Check if book exists
    IF available IS NULL THEN
        RAISE NOTICE 'Book does not exist.';

    -- Check if enough copies are available
    ELSIF available < p_quantity THEN
        RAISE NOTICE 'Not enough copies available.';

    ELSE
        -- Reduce available copies
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

          INSERT INTO book_loans
        (student_number, book_id, quantity, loan_status)
        VALUES
        (p_student_number, p_book_id, p_quantity, 'BORROWED');

        RAISE NOTICE 'Book borrowed successfully.';

    END IF;

END;
$$;

-- QUESTION 5

-- Valid loan 1
CALL borrow_book('202600001', 1, 2);

-- Valid loan 2
CALL borrow_book('202600002', 2, 1);

-- Request exceeding available copies
CALL borrow_book('202600003', 3, 10);


SELECT * FROM books;

SELECT * FROM book_loans;


-- QUESTION 6
-- Procedure to return a book

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    returned_book_id INT;
    returned_quantity INT;
    current_status VARCHAR;
BEGIN

    -- Find the loan
    SELECT book_id, quantity, loan_status
    INTO returned_book_id, returned_quantity, current_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    -- Check if loan exists
    IF returned_book_id IS NULL THEN
        RAISE NOTICE 'Loan does not exist.';

    -- Check if already returned
    ELSIF current_status = 'RETURNED' THEN
        RAISE NOTICE 'This loan has already been returned.';

    ELSE
        -- Restore the book copies
        UPDATE books
        SET available_copies = available_copies + returned_quantity
        WHERE book_id = returned_book_id;

        -- Mark the loan as returned
        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully.';

    END IF;

END;
$$;

-- Return loan 1
CALL return_book(1);

-- Try returning the same loan again
CALL return_book(1);

-- Check the results
SELECT * FROM books;
SELECT * FROM book_loans;

--question 7
--explicit cursor for books with few copies

DO $$
DECLARE
    book_record RECORD;

    book_cursor CURSOR FOR
        SELECT book_id, book_title, available_copies
        FROM books
        WHERE available_copies <= 2;

BEGIN

    OPEN book_cursor;

    LOOP

        FETCH book_cursor INTO book_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Book ID: %, Title: %, Available Copies: %',
        book_record.book_id,
        book_record.book_title,
        book_record.available_copies;

    END LOOP;

    CLOSE book_cursor;

END $$;

-- QUESTION 8
-- Handle invalid quantity using EXCEPTION

DO $$
DECLARE
    quantity_to_borrow INT := 0;
BEGIN

    IF quantity_to_borrow <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity. Quantity must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;

END $$;

--QUESTION 9
SELECT* FROM books;
SELECT*FROM book_loans;
