-- =============================================================================
-- 01_bronze_load.sql
-- Purpose: Bulk load raw CSV data into Bronze layer using standard INSERT.
-- Method: INSERT statements (portable across environments without FILE privilege).
-- Note:   For high-volume production loads, use 01_bronze_load_infile.sql instead.
-- =============================================================================

USE medallion_dw;

-- Truncate Bronze tables before reload (idempotent full load)
TRUNCATE TABLE bronze_customers;
TRUNCATE TABLE bronze_employees;
TRUNCATE TABLE bronze_products;
TRUNCATE TABLE bronze_orders;
TRUNCATE TABLE bronze_orders_archive;

-- -----------------------------------------------------------------------------
-- Load: Customers.csv
-- -----------------------------------------------------------------------------
INSERT INTO bronze_customers (CustomerID, FirstName, LastName, Country, Score) VALUES
('1',  'Alice',   'Johnson',  'USA',       '85'),
('2',  'Bob',     'Smith',    'USA',       '72'),
('3',  'Charlie', 'Williams', 'UK',        '95'),
('4',  'Diana',   'Brown',    'Canada',    '45'),
('5',  'Edward',  'Davis',    'Germany',   '88'),
('6',  'Fiona',   'Miller',   'France',    '63'),
('7',  'George',  'Wilson',   'Australia', '55'),
('8',  'Hannah',  'Moore',    'USA',       '91'),
('9',  'Ian',     'Taylor',   'UK',        '38'),
('10', 'Julia',   'Anderson', 'Canada',    '77'),
('11', 'Kevin',   'Thomas',   'USA',       '52'),
('12', 'Laura',   'Jackson',  'Germany',   '84'),
('13', 'Mark',    'White',    'France',    ''),      -- intentional NULL Score for cleansing demo
('14', 'Nina',    'Harris',   'USA',       '68'),
('15', 'Oscar',   'Martin',   'Australia', '49');

-- -----------------------------------------------------------------------------
-- Load: Employees.csv
-- -----------------------------------------------------------------------------
INSERT INTO bronze_employees (EmployeeID, FirstName, LastName, Department, BirthDate, Gender, Salary, ManagerID) VALUES
('1',  'John',        'Reynolds',   'Sales',       '1985-03-15', 'M', '75000',  ''),   -- top-level manager
('2',  'Sarah',       'Chen',       'Sales',       '1990-07-22', 'F', '62000',  '1'),
('3',  'Michael',     'Patel',      'Sales',       '1988-11-08', 'M', '58000',  '1'),
('4',  'Emily',       'Rodriguez',  'Marketing',   '1992-01-30', 'F', '55000',  '5'),
('5',  'David',       'Kim',        'Marketing',   '1987-06-12', 'M', '68000',  ''),   -- top-level manager
('6',  'Jessica',     'Lee',        'Engineering', '1991-09-05', 'F', '82000',  '8'),
('7',  'Robert',      'Garcia',     'Engineering', '1984-04-18', 'M', '91000',  '8'),
('8',  'Amanda',      'Thompson',   'Engineering', '1980-08-25', 'F', '105000', ''),   -- top-level manager
('9',  'Christopher', 'Brown',      'Sales',       '1993-12-03', 'M', '54000',  '2'),
('10', 'Olivia',      'Clark',      'Marketing',   '1995-02-14', 'F', '48000',  '5'),
('11', 'Daniel',      'Lewis',      'Engineering', '1989-10-29', 'M', '78000',  '7'),
('12', 'Rachel',      'Walker',     'HR',          '1990-05-17', 'F', '52000',  '5'),
('13', 'Thomas',      'Hall',       'Sales',       '1986-07-09', 'M', '60000',  '3'),
('14', 'Anna',        'Young',      'HR',          '1993-03-21', 'F', '47000',  '12'),
('15', 'James',       'Allen',      'Sales',       '1994-08-11', 'M', '51000',  '2');

-- -----------------------------------------------------------------------------
-- Load: Products.csv
-- -----------------------------------------------------------------------------
INSERT INTO bronze_products (ProductID, Product, Category, Price) VALUES
('1',  'Laptop Pro 15',            'Electronics', '1299.99'),
('2',  'Wireless Mouse',           'Electronics', '29.99'),
('3',  'Ergonomic Chair',          'Furniture',   '449.99'),
('4',  'Standing Desk',            'Furniture',   '799.99'),
('5',  'Python Programming',       'Book',        '49.99'),
('6',  'Data Science Handbook',    'Book',        '59.99'),
('7',  'Coffee Maker',             'Appliance',   '89.99'),
('8',  'Noise Canceling Headphones','Electronics','349.99'),
('9',  'Office Lamp',              'Furniture',   '79.99'),
('10', 'SQL Mastery',              'Book',        '44.99'),
('11', 'Tablet Mini',              'Electronics', '499.99'),
('12', 'Water Dispenser',          'Appliance',   '129.99'),
('13', 'Keyboard Mechanical',      'Electronics', '159.99'),
('14', 'Monitor 27inch',           'Electronics', '399.99'),
('15', 'Bookshelf',                'Furniture',   '199.99');

-- -----------------------------------------------------------------------------
-- Load: Orders.csv
-- -----------------------------------------------------------------------------
INSERT INTO bronze_orders (OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime) VALUES
('1001', '1',  '1',  '2',  '2024-01-15', '2024-01-18', 'Delivered', '123 Main St New York NY',       '123 Main St New York NY',       '1', '1299.99', '2024-01-15 09:30:00'),
('1002', '2',  '2',  '9',  '2024-02-20', '2024-02-22', 'Shipped',   '456 Oak Ave Los Angeles CA',    '456 Oak Ave Los Angeles CA',    '3', '89.97',   '2024-02-20 14:15:00'),
('1003', '3',  '3',  '13', '2024-03-10', '2024-03-14', 'Delivered', '78 Baker St London UK',         '78 Baker St London UK',         '2', '899.98',  '2024-03-10 11:00:00'),
('1004', '5',  '4',  '2',  '2024-04-05', '2024-04-08', 'Delivered', '22 Maple Rd Toronto ON',        '22 Maple Rd Toronto ON',        '5', '249.95',  '2024-04-05 16:45:00'),
('1005', '8',  '5',  '3',  '2024-05-12', '2024-05-15', 'Delivered', '10 Berlin Str Berlin DE',       '10 Berlin Str Berlin DE',       '1', '349.99',  '2024-05-12 10:20:00'),
('1006', '11', '6',  '9',  '2024-06-18', '2024-06-20', 'Shipped',   '5 Rue Paris Paris FR',          '5 Rue Paris Paris FR',          '2', '999.98',  '2024-06-18 13:30:00'),
('1007', '7',  '7',  '13', '2024-07-22', '2024-07-25', 'Delivered', '88 Sydney Rd Sydney AU',        '88 Sydney Rd Sydney AU',        '1', '89.99',   '2024-07-22 08:50:00'),
('1008', '14', '8',  '2',  '2024-08-30', '2024-09-02', 'Delivered', '300 Pine St Chicago IL',        '300 Pine St Chicago IL',        '3', '1199.97', '2024-08-30 17:10:00'),
('1009', '10', '9',  '3',  '2024-09-14', '2024-09-16', 'Delivered', '44 Thames St London UK',        '44 Thames St London UK',        '4', '179.96',  '2024-09-14 12:25:00'),
('1010', '4',  '10', '13', '2024-10-08', '2024-10-12', 'Delivered', '55 Queen St Toronto ON',        '55 Queen St Toronto ON',        '1', '799.99',  '2024-10-08 09:40:00'),
('1011', '13', '11', '9',  '2024-11-19', '2024-11-21', 'Shipped',   '77 Elm St Houston TX',          '77 Elm St Houston TX',          '2', '319.98',  '2024-11-19 15:55:00'),
('1012', '6',  '12', '2',  '2024-12-03', '2024-12-06', 'Delivered', '12 Munich Allee Munich DE',     '12 Munich Allee Munich DE',     '3', '179.97',  '2024-12-03 11:15:00'),
('1013', '1',  '14', '3',  '2025-01-10', '2025-01-13', 'Delivered', '200 Cedar Ln Boston MA',        '200 Cedar Ln Boston MA',        '1', '1299.99', '2025-01-10 10:00:00'),
('1014', '8',  '15', '13', '2025-02-14', '2025-02-17', 'Shipped',   '33 Melbourne Ave Melbourne AU', '33 Melbourne Ave Melbourne AU', '2', '699.98',  '2025-02-14 14:30:00'),
('1015', '15', '1',  '9',  '2025-03-05', '2025-03-08', 'Delivered', '123 Main St New York NY',       '123 Main St New York NY',       '1', '199.99',  '2025-03-05 16:20:00');

-- -----------------------------------------------------------------------------
-- Load: OrdersArchive.csv
-- -----------------------------------------------------------------------------
INSERT INTO bronze_orders_archive (OrderID, ProductID, CustomerID, SalesPersonID, OrderDate, ShipDate, OrderStatus, ShipAddress, BillAddress, Quantity, Sales, CreationTime) VALUES
('501', '1',  '3',  '2',  '2022-01-20', '2022-01-24', 'Delivered', '78 Baker St London UK',         '78 Baker St London UK',         '1', '1299.99', '2022-01-20 09:00:00'),
('502', '3',  '1',  '9',  '2022-03-15', '2022-03-18', 'Delivered', '123 Main St New York NY',       '123 Main St New York NY',       '1', '449.99',  '2022-03-15 11:30:00'),
('503', '5',  '2',  '13', '2022-05-08', '2022-05-10', 'Delivered', '456 Oak Ave Los Angeles CA',    '456 Oak Ave Los Angeles CA',    '2', '99.98',   '2022-05-08 14:00:00'),
('504', '8',  '5',  '3',  '2022-07-12', '2022-07-15', 'Delivered', '10 Berlin Str Berlin DE',       '10 Berlin Str Berlin DE',       '1', '349.99',  '2022-07-12 10:45:00'),
('505', '2',  '4',  '2',  '2022-09-22', '2022-09-24', 'Shipped',   '22 Maple Rd Toronto ON',        '22 Maple Rd Toronto ON',        '5', '149.95',  '2022-09-22 16:20:00'),
('506', '11', '6',  '9',  '2022-11-05', '2022-11-08', 'Delivered', '5 Rue Paris Paris FR',          '5 Rue Paris Paris FR',          '1', '499.99',  '2022-11-05 13:10:00'),
('507', '7',  '7',  '13', '2023-01-18', '2023-01-21', 'Delivered', '88 Sydney Rd Sydney AU',        '88 Sydney Rd Sydney AU',        '2', '179.98',  '2023-01-18 08:30:00'),
('508', '14', '8',  '2',  '2023-03-25', '2023-03-28', 'Delivered', '300 Pine St Chicago IL',        '300 Pine St Chicago IL',        '2', '799.98',  '2023-03-25 17:00:00'),
('509', '10', '9',  '3',  '2023-05-30', '2023-06-02', 'Delivered', '44 Thames St London UK',        '44 Thames St London UK',        '3', '134.97',  '2023-05-30 12:15:00'),
('510', '4',  '10', '13', '2023-07-14', '2023-07-18', 'Delivered', '55 Queen St Toronto ON',        '55 Queen St Toronto ON',        '1', '799.99',  '2023-07-14 09:50:00'),
('511', '6',  '11', '9',  '2023-09-08', '2023-09-11', 'Shipped',   '77 Elm St Houston TX',          '77 Elm St Houston TX',          '4', '239.96',  '2023-09-08 15:40:00'),
('512', '13', '12', '2',  '2023-11-20', '2023-11-23', 'Delivered', '12 Munich Allee Munich DE',     '12 Munich Allee Munich DE',     '1', '159.99',  '2023-11-20 11:25:00'),
('513', '1',  '14', '3',  '2023-12-15', '2023-12-18', 'Delivered', '200 Cedar Ln Boston MA',        '200 Cedar Ln Boston MA',        '2', '2599.98', '2023-12-15 10:10:00'),
('514', '15', '15', '13', '2022-06-28', '2022-07-01', 'Delivered', '33 Melbourne Ave Melbourne AU', '33 Melbourne Ave Melbourne AU', '1', '199.99',  '2022-06-28 14:55:00'),
('515', '12', '1',  '9',  '2023-10-03', '2023-10-06', 'Delivered', '123 Main St New York NY',       '123 Main St New York NY',       '1', '129.99',  '2023-10-03 16:30:00');
