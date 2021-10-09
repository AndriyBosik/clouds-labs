-- Знайти всіх співробітників, що ніколи не надавали знижок. Навіть якщо такі на даний момент відсутні.
SELECT e.* FROM Employees e
LEFT JOIN Orders o ON o.EmployeeID=e.EmployeeID
LEFT JOIN `Order Details` od ON od.OrderID=o.OrderID
GROUP BY e.EmployeeID
HAVING SUM(COALESCE(od.Discount, 0))=0

-- Показати всі персональні дані з бази Northwind: повне ім’я, країну, місто, адресу, телефон. Звернути увагу, що ця інформація присутня в різних таблицях.
SELECT ContactName AS FullName, Country, City, Address, Phone FROM Customers
UNION
SELECT CONCAT(FirstName, ' ', LastName) AS FullName, Country, City, Address, HomePhone AS Phone FROM Employees
UNION
SELECT ContactName AS FullName, Country, City, Address, Phone FROM Suppliers

-- Відобразити список всіх країн та міст, куди компанія робила відправлення. Позбавитися порожніх значень на дублікатів.
SELECT DISTINCT s.CompanyName, o.ShipCity, o.ShipCountry
FROM Shippers s
LEFT JOIN Orders o ON o.ShipVia=s.ShipperID

-- Використовуючи базу Northwind вивести в алфавітному порядку назви продуктів та їх сумарну кількість в замовленнях.
SELECT p.ProductName, SUM(COALESCE(od.Quantity, 0)) AS `ProductName` FROM Products p
LEFT JOIN `Order Details` od ON od.ProductID=p.ProductID
GROUP BY p.ProductID
ORDER BY p.ProductName

-- Вивести імена всіх постачальників та сумарну вартість їх товарів, що зараз знаходяться на складі Northwind за умови, що ця сума більше $1000.
SELECT s.ContactName, SUM(p.UnitPrice*UnitsInStock) FROM Suppliers s
LEFT JOIN Products p ON p.SupplierID=s.SupplierID
GROUP BY s.SupplierID
HAVING SUM(p.UnitPrice*UnitsInStock) > 1000

-- Знайти кількість замовлень, де фігурують товари з категорії «Сири». Результат має містити дві колонки: опис категорії та кількість замовлень.
SELECT
    c.Description,    
    (
        SELECT COUNT(DISTINCT od.OrderID)
        FROM `Order Details` od
        WHERE EXISTS (
            SELECT NULL
            FROM Products p
            WHERE p.ProductID=od.ProductID AND p.CategoryID=c.CategoryID
        )
    ) AS OrdersCount
FROM Categories c
WHERE c.Description LIKE 'Cheeses'

-- Відобразити всі імена компаній-замовників та загальну суму всіх їх замовлень, враховуючи кількість товару та знижки. Показати навіть ті компанії, у яких замовлення відсутні. Позбавитися від відсутніх значень замінивши їх на нуль. Округлити числові результати до двох знаків після коми, відсортувати за алфавітом.
SELECT DISTINCT
    c.CompanyName,
    CAST(COALESCE((
        SELECT SUM(od.UnitPrice*od.Quantity*(1 - od.Discount/100))
        FROM `Order Details` od
        WHERE EXISTS (
            SELECT NULL
            FROM Orders o
            WHERE od.OrderID=o.OrderID AND o.CustomerID=c.CustomerID
        )
    ), 0) AS DECIMAL(20, 2)) AS OrdersSum
FROM Customers c
ORDER BY c.CompanyName

-- Вивести три колонки: співробітника (прізвище та ім’я, включаючи офіційне звернення), компанію, з якою співробітник найбільше працював згідно величини товарообігу (максимальна сума по усім замовленням в розрізі компанії), та ім’я представника компанії, додавши до останнього через кому посаду. Цікавить інформація тільки за 1998 рік.
SELECT FullName, CompanyName, ContactName FROM (
    SELECT DISTINCT
        CONCAT(e.TitleOfCourtesy, ' ', e.LastName, ' ', e.FirstName) AS FullName,
        COALESCE(c.CompanyName, '') AS CompanyName,
        COALESCE(CONCAT(c.ContactName, '(', c.ContactTitle, ')'), '') AS ContactName,
        COALESCE((
            SELECT SUM(od.UnitPrice*od.Quantity*(1 - od.Discount))
            FROM `Order Details` od
            WHERE EXISTS (
                SELECT NULL FROM Orders o
                WHERE o.OrderID=od.OrderID AND
                    o.EmployeeID=e.EmployeeID AND
                    o.CustomerID=c.CustomerID AND
                    year(o.ShippedDate)=1998
            )
        ), 0) AS Total
    FROM Employees e
    LEFT JOIN Orders o ON o.EmployeeID=e.EmployeeID
    LEFT JOIN Customers c ON c.CustomerID=o.CustomerID
    ORDER BY FullName, Total DESC
) Derived
GROUP BY FullName

-- Вивести три колонки та три рядки.
-- Колонки: Description, Key, Value.
-- Рядки:
-- 1) ShippedDate, дата з максимальною кількістю відправлених замовлень, кількість відправлених замовлень на цю дату;
-- 2) Customer, замовник з максимальною кількістю відправлених замовлень, загальна кількість відправлених замовлень цьому замовнику;
-- 3) Shipper, перевізник з максимальною кількістю оброблених замовлень, загальна кількість відправлених через цього перевізника.
(
    SELECT
        'ShippedDate' AS `Description`,
        o.ShippedDate AS `Key`,
        COUNT(o.OrderID) AS `Value`
    FROM Orders o
    WHERE NOT o.ShippedDate IS NULL
    GROUP BY o.ShippedDate
    ORDER BY `Value` DESC
    LIMIT 1
)
UNION
(
    SELECT
        'Customer' AS `Description`,
        c.ContactName,
        COUNT(o.OrderID) AS `Value`
    FROM Customers c
    LEFT JOIN Orders o ON c.CustomerID=o.CustomerID
    GROUP BY c.CustomerID
    ORDER BY `Value` DESC
    LIMIT 1
)
UNION
(
    SELECT
        'Shipper' AS `Description`,
        s.CompanyName,
        COUNT(o.OrderID) AS `Value`
    FROM Shippers s
    LEFT JOIN Orders o ON s.ShipperID=o.ShipVia
    GROUP BY s.ShipperID
    ORDER BY `Value` DESC
    LIMIT 1
)

-- Вивести найбільш популярній товари в розрізі країни. Показати: назву країни, назву продукту, загальну вартість поставок за весь час. Не використовувати функцій ранкування та партиціонування.
SELECT ShipCountry, ProductName, TotalPrice FROM (
    SELECT
        o.ShipCountry AS ShipCountry,
        p.ProductName AS ProductName,
        SUM(od.Quantity) AS Quantity,
        SUM((od.Quantity*od.UnitPrice*(1 - od.Discount))) AS TotalPrice
    FROM Orders o
    LEFT JOIN `Order Details` od ON od.OrderID=o.OrderID
    LEFT JOIN `Products` p ON p.ProductID=od.ProductID
    GROUP BY o.ShipCountry, p.ProductName
    ORDER BY o.ShipCountry, Quantity DESC
) Derived
GROUP BY ShipCountry