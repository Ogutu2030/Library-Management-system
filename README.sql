# Library-Management-system
-- Library Management System Database

-- Drop database if it exists (for clean initialization)
DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management;
USE library_management;

-- TABLES CREATION

-- Members table (stores library users' information)
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    address VARCHAR(255),
    date_of_birth DATE,
    registration_date DATE NOT NULL,
    membership_status ENUM('Active', 'Expired', 'Suspended') NOT NULL DEFAULT 'Active',
    membership_expiry DATE NOT NULL
);

-- Member_cards table (1-1 relationship with members)
CREATE TABLE member_cards (
    card_id INT AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Authors table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year INT,
    death_year INT,
    nationality VARCHAR(50),
    biography TEXT
);

-- Publishers table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15),
    established_year INT
);

-- Categories table
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    parent_category_id INT,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- Books table
CREATE TABLE books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    publisher_id INT,
    publication_year INT,
    edition VARCHAR(20),
    language VARCHAR(30) DEFAULT 'English',
    page_count INT,
    description TEXT,
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL
);

-- Book copies table (represents physical instances of books)
CREATE TABLE book_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    acquisition_date DATE NOT NULL,
    cost DECIMAL(10, 2),
    status ENUM('Available', 'On Loan', 'Reserved', 'Lost', 'Under Repair') NOT NULL DEFAULT 'Available',
    location VARCHAR(50) NOT NULL,
    condition_rating ENUM('New', 'Good', 'Fair', 'Poor') NOT NULL DEFAULT 'New',
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE
);

-- Book_authors (many-to-many relationship between books and authors)
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,
    role ENUM('Primary', 'Co-author', 'Editor', 'Translator') DEFAULT 'Primary',
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Book_categories (many-to-many relationship between books and categories)
CREATE TABLE book_categories (
    book_id INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (book_id, category_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- Loans table (tracks borrowed books)
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checkout_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    renewed_times INT DEFAULT 0 CHECK (renewed_times >= 0 AND renewed_times <= 3),
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Reservations table
CREATE TABLE reservations (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Expired', 'Cancelled') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Fines table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    reason ENUM('Late Return', 'Damaged Item', 'Lost Item') NOT NULL,
    issued_date DATE NOT NULL,
    paid_date DATE,
    payment_status ENUM('Pending', 'Paid', 'Waived') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
);

-- Library staff table
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    role ENUM('Librarian', 'Assistant', 'Admin', 'IT Support') NOT NULL,
    hire_date DATE NOT NULL,
    department VARCHAR(50),
    supervisor_id INT,
    FOREIGN KEY (supervisor_id) REFERENCES staff(staff_id) ON DELETE SET NULL
);

-- SAMPLE DATA INSERTION

-- Sample Members
INSERT INTO members (first_name, last_name, email, phone_number, address, date_of_birth, registration_date, membership_status, membership_expiry)
VALUES
    ('John', 'Smith', 'john.smith@email.com', '555-123-4567', '123 Main St, Anytown', '1985-03-15', '2023-01-10', 'Active', '2025-01-10'),
    ('Emma', 'Johnson', 'emma.j@email.com', '555-234-5678', '456 Oak Ave, Somecity', '1992-07-22', '2023-02-15', 'Active', '2025-02-15'),
    ('Michael', 'Brown', 'mbrown@email.com', '555-345-6789', '789 Pine Rd, Otherville', '1978-11-05', '2023-03-20', 'Active', '2025-03-20'),
    ('Sarah', 'Davis', 'sarah.d@email.com', '555-456-7890', '101 Elm St, Anytown', '1990-05-30', '2023-04-25', 'Suspended', '2025-04-25'),
    ('David', 'Wilson', 'dwilson@email.com', '555-567-8901', '202 Maple Dr, Somecity', '1982-09-18', '2023-05-30', 'Active', '2025-05-30');

-- Sample Member Cards
INSERT INTO member_cards (member_id, issue_date, expiry_date)
VALUES
    (1, '2023-01-10', '2025-01-10'),
    (2, '2023-02-15', '2025-02-15'),
    (3, '2023-03-20', '2025-03-20'),
    (4, '2023-04-25', '2025-04-25'),
    (5, '2023-05-30', '2025-05-30');

-- Sample Authors
INSERT INTO authors (first_name, last_name, birth_year, death_year, nationality, biography)
VALUES
    ('Jane', 'Austen', 1775, 1817, 'British', 'Famous for works like Pride and Prejudice and Sense and Sensibility.'),
    ('George', 'Orwell', 1903, 1950, 'British', 'Known for dystopian novel 1984 and Animal Farm.'),
    ('J.K.', 'Rowling', 1965, NULL, 'British', 'Author of the Harry Potter series.'),
    ('Haruki', 'Murakami', 1949, NULL, 'Japanese', 'Contemporary writer known for surrealist works.'),
    ('Agatha', 'Christie', 1890, 1976, 'British', 'The Queen of Mystery, wrote numerous detective novels.');

-- Sample Publishers
INSERT INTO publishers (name, address, contact_email, contact_phone, established_year)
VALUES
    ('Penguin Random House', '1745 Broadway, New York, NY', 'info@penguinrandomhouse.com', '212-782-9000', 1927),
    ('HarperCollins', '195 Broadway, New York, NY', 'contact@harpercollins.com', '212-207-7000', 1817),
    ('Simon & Schuster', '1230 Avenue of the Americas, New York, NY', 'info@simonandschuster.com', '212-698-7000', 1924),
    ('Macmillan Publishers', '120 Broadway, New York, NY', 'contact@macmillan.com', '646-307-5151', 1843),
    ('Hachette Book Group', '1290 Avenue of the Americas, New York, NY', 'info@hachettebookgroup.com', '212-364-1100', 1837);

-- Sample Categories
INSERT INTO categories (name, description, parent_category_id)
VALUES
    ('Fiction', 'Literary works created from imagination', NULL),
    ('Non-Fiction', 'Informational and factual writing', NULL),
    ('Mystery', 'Fiction dealing with solving a crime or puzzle', 1),
    ('Science Fiction', 'Fiction with scientific or technological elements', 1),
    ('Biography', 'Non-fiction account of a person\'s life', 2),
    ('History', 'Non-fiction about past events', 2),
    ('Fantasy', 'Fiction with magical or supernatural elements', 1),
    ('Self-Help', 'Books aimed at personal improvement', 2);

-- Sample Books
INSERT INTO books (isbn, title, publisher_id, publication_year, edition, language, page_count, description)
VALUES
    ('9780141439518', 'Pride and Prejudice', 1, 1813, 'Reprint', 'English', 432, 'A romantic novel by Jane Austen.'),
    ('9780451524935', '1984', 2, 1949, 'Reprint', 'English', 328, 'A dystopian novel by George Orwell.'),
    ('9780439708180', 'Harry Potter and the Philosopher\'s Stone', 3, 1997, 'First Edition', 'English', 320, 'First book in the Harry Potter series.'),
    ('9780307476463', 'Norwegian Wood', 4, 1987, 'English Translation', 'English', 296, 'A novel by Haruki Murakami.'),
    ('9780062073488', 'Murder on the Orient Express', 5, 1934, 'Reprint', 'English', 256, 'A detective novel by Agatha Christie.');

-- Sample Book Copies
INSERT INTO book_copies (book_id, acquisition_date, cost, status, location, condition_rating)
VALUES
    (1, '2023-01-15', 15.99, 'Available', 'Fiction Section A1', 'Good'),
    (1, '2023-01-15', 15.99, 'On Loan', 'Fiction Section A1', 'Good'),
    (2, '2023-02-20', 14.50, 'Available', 'Fiction Section B3', 'New'),
    (3, '2023-03-25', 20.75, 'Reserved', 'Fantasy Section C2', 'Good'),
    (3, '2023-03-25', 20.75, 'Available', 'Fantasy Section C2', 'Good'),
    (4, '2023-04-10', 18.25, 'Under Repair', 'Fiction Section D4', 'Poor'),
    (5, '2023-05-05', 12.99, 'Available', 'Mystery Section E2', 'Fair');

-- Sample Book Authors
INSERT INTO book_authors (book_id, author_id, role)
VALUES
    (1, 1, 'Primary'),  -- Jane Austen - Pride and Prejudice
    (2, 2, 'Primary'),  -- George Orwell - 1984
    (3, 3, 'Primary'),  -- J.K. Rowling - Harry Potter
    (4, 4, 'Primary'),  -- Haruki Murakami - Norwegian Wood
    (5, 5, 'Primary');  -- Agatha Christie - Murder on the Orient Express

-- Sample Book Categories
INSERT INTO book_categories (book_id, category_id)
VALUES
    (1, 1),  -- Pride and Prejudice - Fiction
    (2, 1),  -- 1984 - Fiction
    (2, 4),  -- 1984 - Science Fiction
    (3, 1),  -- Harry Potter - Fiction
    (3, 7),  -- Harry Potter - Fantasy
    (4, 1),  -- Norwegian Wood - Fiction
    (5, 1),  -- Murder on the Orient Express - Fiction
    (5, 3);  -- Murder on the Orient Express - Mystery

-- Sample Loans
INSERT INTO loans (copy_id, member_id, checkout_date, due_date, return_date, renewed_times)
VALUES
    (2, 1, '2024-03-01', '2024-03-15', '2024-03-14', 0),                        -- Returned on time
    (4, 2, '2024-03-05', '2024-03-19', NULL, 1),                                -- Still out, renewed once
    (6, 3, '2024-02-20', '2024-03-05', '2024-03-25', 0),                        -- Returned late
    (1, 4, '2024-01-15', '2024-01-29', '2024-01-25', 0),                        -- Returned early
    (5, 5, '2024-03-10', '2024-03-24', NULL, 0);                                -- Still out, not renewed

-- Sample Reservations
INSERT INTO reservations (book_id, member_id, reservation_date, expiry_date, status)
VALUES
    (3, 1, '2024-03-01 10:30:00', '2024-03-08', 'Fulfilled'),
    (2, 3, '2024-03-05 14:45:00', '2024-03-12', 'Pending'),
    (5, 2, '2024-02-20 09:15:00', '2024-02-27', 'Expired'),
    (1, 4, '2024-03-15 16:20:00', '2024-03-22', 'Pending'),
    (4, 5, '2024-03-10 11:00:00', '2024-03-17', 'Cancelled');

-- Sample Fines
INSERT INTO fines (loan_id, amount, reason, issued_date, paid_date, payment_status)
VALUES
    (3, 10.00, 'Late Return', '2024-03-26', NULL, 'Pending'),
    (4, 5.00, 'Damaged Item', '2024-01-25', '2024-01-30', 'Paid'),
    (1, 2.50, 'Late Return', '2024-03-16', '2024-03-20', 'Paid'),
    (2, 15.00, 'Late Return', '2024-03-20', NULL, 'Waived'),
    (5, 7.50, 'Late Return', '2024-03-25', NULL, 'Pending');

-- Sample Staff
INSERT INTO staff (first_name, last_name, email, phone_number, role, hire_date, department, supervisor_id)
VALUES
    ('Robert', 'Garcia', 'rgarcia@library.org', '555-111-2222', 'Admin', '2018-06-15', 'Administration', NULL),
    ('Jennifer', 'Lee', 'jlee@library.org', '555-222-3333', 'Librarian', '2019-04-20', 'Fiction Department', 1),
    ('William', 'Chen', 'wchen@library.org', '555-333-4444', 'Assistant', '2020-09-10', 'Fiction Department', 2),
    ('Maria', 'Rodriguez', 'mrodriguez@library.org', '555-444-5555', 'IT Support', '2021-02-28', 'IT Department', 1),
    ('James', 'Thompson', 'jthompson@library.org', '555-555-6666', 'Librarian', '2019-10-15', 'Non-Fiction Department', 1);
