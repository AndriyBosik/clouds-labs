 -- Використавши SELECT та не використовуючи FROM вивести на екран назву виконавця та пісні, яку ви слухали останньою. Імена колонок вказати як Artist та Title.
 SELECT ‘Imagine Dragons’ AS `Artist`, ‘Zero’ AS `Title`

 -- Вивести вміст таблиці Order Details, замінивши назви атрибутів OrderID та ProductID на OrderNumber та ProductNumber.
 SELECT *, `OrderID` AS `OrderNumber`, `ProductID` AS `ProductNumber` FROM `Order Details`

 -- З таблиці співробітників вивести всіх співробітників, що мають заробітну платню більше 2000.00, проте меншу за 3000.00. Результат відобразити у вигляді двох колонок, де перша – це конкатенація звернення (TitleOfCourtesy), прізвища та імені. Друга колонка – це заробітна плата відсортована у порядку зростання.
 SELECT
    CONCAT(`LastName`, ‘ ’, `FirstName`) AS `TitleOfCourtesy`,
    `Salary`
FROM `Employees`
WHERE `Salary`>2000 AND `Salary`<3000
ORDER BY `Salary`

-- Вивести назву всіх продуктів, що продаються у банках (jar), відсортувати за алфавітом.
SELECT `ProductName`
FROM `Products`
WHERE
    `QuantityPerUnit` LIKE “% jar” OR
    `QuantityPerUnit` LIKE “% jars”
ORDER BY `ProductName`

-- Використовуючи базу Northwind вивести всі замовлення, що були здійснені замовниками Island Trading та Queen Cozinha.
SELECT p.`ProductName`, p.`UnitsInStock`
FROM `Products` p
WHERE EXISTS (
    SELECT NULL
    FROM `Categories` c
    WHERE
        c.`CategoryID`=p.`CategoryID` AND
        c.`CategoryName` IN ('Dairy Products', 'Grains/Cereals', 'Meat/Poultry')
)

-- Вивести всі назви та кількість на складі продуктів, що належать до категорій Dairy Products, Grains/Cereals та Meat/Poultry.
SELECT p.`ProductName`, p.`UnitsInStock`
FROM `Products` p
WHERE EXISTS (
    SELECT NULL
    FROM `Categories` c
    WHERE
        c.`CategoryID`=p.`CategoryID` AND
        c.`CategoryName` IN ('Dairy Products', 'Grains/Cereals', 'Meat/Poultry')
)

-- Вивести всі замовлення, де вартість одиниці товару 50.00 та вище. Відсортувати за номером, позбавитися дублікатів.
SELECT * FROM `Order Details` WHERE `UnitPrice` >= 50
GROUP BY `OrderID`, `ProductID`
ORDER BY `OrderID`

-- Відобразити всіх постачальників, де контактною особою є власник, або менеджер і є продукти, що зараз знаходяться на стадії поставки.
SELECT *
FROM `Suppliers` s
WHERE (s.`ContactTitle` LIKE "% Manager" OR s.`ContactTitle`="Owner") AND EXISTS (
    SELECT NULL
    FROM `Products` p
    WHERE s.`SupplierID`=p.`SupplierID` AND NOT p.`Discontinued`
)

-- Вивести всіх замовників з Мексики, де контактною особою є власник, а доставка товарів відбувалася через Federal Shipping.
SELECT *
FROM `Customers` c
WHERE c.`Country`='Mexico' AND c.`ContactTitle`='Owner' AND EXISTS (
    SELECT NULL FROM `Orders` o WHERE o.`CustomerID`=c.`CustomerID` AND EXISTS (
        SELECT NULL
        FROM `Shippers` s
        WHERE s.`ShipperID`=o.`ShipVia` AND s.`CompanyName`='Federal Shipping'
    )
)

-- 