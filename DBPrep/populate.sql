--Dr. Sean Murthy
--Script to add sample data to PVFC tables: tables should have already been created
--Removes all existing data and adds some initial
--This script can only modify data for tables in your dedicated schema

--The script was ported from the Oracle version provided by the textbook authors
--Minimal changes were made to the Oracle version (though some of the content is unnecessary/inefficient)


--clear existing data

DELETE FROM Uses_T;
DELETE FROM WorksIn_T;
DELETE FROM WorkCenter_T;
DELETE FROM DoesBusinessIn_T;
DELETE FROM EmployeeSkills_T;
DELETE FROM Supplies_T;
DELETE FROM ProducedIn_T;
DELETE FROM OrderLine_T;
DELETE FROM Product_T;
DELETE FROM ProductLine_T;
DELETE FROM Order_T;
DELETE FROM Salesperson_T;
DELETE FROM Vendor_T;
DELETE FROM Skill_T;
DELETE FROM RawMaterial_T;
DELETE FROM Territory_T;
DELETE FROM Employee_T;
DELETE FROM Customer_T;
DELETE FROM Users;


--add sample data: there is a better way than what is shown here to insert bulk data


INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (1, 'Contemporary Casuals', '1355 S Hines Blvd', 'Gainesville', 'FL', '32601-2871');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (2, 'Value Furniture', '15145 S.W. 17th St.', 'Plano', 'TX', '75094-7743');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (3, 'Home Furnishings', '1900 Allard Ave.', 'Albany', 'NY', '12209-1125');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (4, 'Eastern Furniture', '1925 Beltline Rd.', 'Carteret', 'NJ', '07008-3188');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (5, 'Impressions', '5585 Westcott Ct.', 'Sacramento', 'CA', '94206-4056');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (6, 'Furniture Gallery', '325 Flatiron Dr.', 'Boulder', 'CO', '80514-4432');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (7, 'Period Furniture', '394 Rainbow Dr.', 'Seattle', 'WA', '97954-5589');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (8, 'California Classics', '816 Peach Rd.', 'Santa Clara', 'CA', '96915-7754');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (9, 'M and H Casual Furniture', '3709 First Street', 'Clearwater', 'FL', '34620-2314');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (10, 'Seminole Interiors', '2400 Rocky Point Dr.', 'Seminole', 'FL', '34646-4423');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (11, 'American Euro Lifestyles', '2424 Missouri Ave N.', 'Prospect Park', 'NJ', '07508-5621');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (12, 'Battle Creek Furniture', '345 Capitol Ave. SW', 'Battle Creek', 'MI', '49015-3401');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (13, 'Heritage Furnishings', '66789 College Ave.', 'Carlisle', 'PA', '17013-8834');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (14, 'Kaneohe Homes', '112 Kiowai St.', 'Kaneohe', 'HI', '96744-2537');
INSERT INTO Customer_T  (CustomerID, CustomerName, CustomerAddress, CustomerCity, CustomerState, CustomerPostalCode)
VALUES  (15, 'Mountain Scenes', '4132 Main Street', 'Ogden', 'UT', '84403-4432');



INSERT INTO Territory_T  (TerritoryID, TerritoryName)
VALUES  (1, 'SouthEast');
INSERT INTO Territory_T  (TerritoryID, TerritoryName)
VALUES  (2, 'SouthWest');
INSERT INTO Territory_T  (TerritoryID, TerritoryName)
VALUES  (3, 'NorthEast');
INSERT INTO Territory_T  (TerritoryID, TerritoryName)
VALUES  (4, 'NorthWest');
INSERT INTO Territory_T  (TerritoryID, TerritoryName)
VALUES  (5, 'Central');





INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (1, 1);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (1, 2);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (2, 2);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (3, 3);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (4, 3);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (5, 2);
INSERT INTO DoesBusinessIn_T  (CustomerID, TerritoryID)
VALUES  (6, 5);





INSERT INTO Employee_T  (EmployeeID, EmployeeName, EmployeeAddress, EmployeeCity, EmployeeState, EmployeeZipCode, EmployeeDateHired, EmployeeBirthDate, EmployeeSupervisor)
VALUES  ('123-44-345', 'Jim Jason', '2134 Hilltop Rd', '', 'TN', '', DATE '12/Jun/99', NULL, '454-56-768');
INSERT INTO Employee_T  (EmployeeID, EmployeeName, EmployeeAddress, EmployeeCity, EmployeeState, EmployeeZipCode, EmployeeDateHired, EmployeeBirthDate, EmployeeSupervisor)
VALUES  ('454-56-768', 'Robert Lewis', '17834 Deerfield Ln', 'Nashville', 'TN', '', DATE '01/Jan/99', NULL, '');




INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('BS12', '12in Band Saw');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('QC1', 'Quality Control');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('RT1', 'Router');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('SO1', 'Sander-Orbital');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('SB1', 'Sander-Belt');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('TS10', '10in Table Saw');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('TS12', '12in Table Saw');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('UC1', 'Upholstery Cutter');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('US1', 'Upholstery Sewer');
INSERT INTO Skill_T  (SkillID, SkillDescription)
VALUES  ('UT1', 'Upholstery Tacker');




INSERT INTO EmployeeSkills_T  (EmployeeID, SkillID)
VALUES  ('123-44-345', 'BS12');
INSERT INTO EmployeeSkills_T  (EmployeeID, SkillID)
VALUES  ('123-44-345', 'RT1');
INSERT INTO EmployeeSkills_T  (EmployeeID, SkillID)
VALUES  ('454-56-768', 'BS12');






INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1001, DATE '21/Oct/15', 1);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1002, DATE '21/Oct/15', 8);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1003, DATE '22/Oct/15', 15);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1004, DATE '22/Oct/15', 5);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1005, DATE '24/Oct/15', 3);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1006, DATE '24/Oct/15', 2);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1007, DATE '27/Oct/15', 11);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1008, DATE '30/Oct/15', 12);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1009, DATE '05/Nov/15', 4);
INSERT INTO Order_T  (OrderID, OrderDate, CustomerID)
VALUES  (1010, DATE '05/Nov/15', 1);




INSERT INTO ProductLine_T  (ProductLineID, ProductLineName)
VALUES  (1, 'Cherry Tree');
INSERT INTO ProductLine_T  (ProductLineID, ProductLineName)
VALUES  (2, 'Scandinavia');
INSERT INTO ProductLine_T  (ProductLineID, ProductLineName)
VALUES  (3, 'Country Look');


INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (1, 'End Table', 'Cherry', 175, 1);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (2, 'Coffee Table', 'Natural Ash', 200, 2);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (3, 'Computer Desk', 'Natural Ash', 375, 2);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (4, 'Entertainment Center', 'Natural Maple', 650, 3);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (5, 'Writers Desk', 'Cherry', 325, 1);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (6, '8-Drawer Desk', 'White Ash', 750, 2);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (7, 'Dining Table', 'Natural Ash', 800, 2);
INSERT INTO Product_T  (ProductID, ProductDescription, ProductFinish, ProductStandardPrice, ProductLineID)
VALUES  (8, 'Computer Desk', 'Walnut', 250, 3);




INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1001, 1, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1001, 2, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1001, 4, 1);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1002, 3, 5);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1003, 3, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1004, 6, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1004, 8, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1005, 4, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1006, 4, 1);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1006, 5, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1006, 7, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1007, 1, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1007, 2, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1008, 3, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1008, 8, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1009, 4, 2);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1009, 7, 3);
INSERT INTO OrderLine_T  (OrderID, ProductID, OrderedQuantity)
VALUES  (1010, 8, 10);



INSERT INTO Salesperson_T  (SalesPersonID, SalesPersonName, SalesPersonPhone, SalesPersonFax, TerritoryID)
VALUES  (1, 'Doug Henny', '8134445555', '', 1);
INSERT INTO Salesperson_T  (SalesPersonID, SalesPersonName, SalesPersonPhone, SalesPersonFax, TerritoryID)
VALUES  (2, 'Robert Lewis', '8139264006', '', 2);
INSERT INTO Salesperson_T  (SalesPersonID, SalesPersonName, SalesPersonPhone, SalesPersonFax, TerritoryID)
VALUES  (3, 'William Strong', '5053821212', '', 3);
INSERT INTO Salesperson_T  (SalesPersonID, SalesPersonName, SalesPersonPhone, SalesPersonFax, TerritoryID)
VALUES  (4, 'Julie Dawson', '4355346677', '', 4);
INSERT INTO Salesperson_T  (SalesPersonID, SalesPersonName, SalesPersonPhone, SalesPersonFax, TerritoryID)
VALUES  (5, 'Jacob Winslow', '2238973498', '', 5);


INSERT INTO WorkCenter_T  (WorkCenterID, WorkCenterLocation)
VALUES  ('SM1', 'Main Saw Mill');
INSERT INTO WorkCenter_T  (WorkCenterID, WorkCenterLocation)
VALUES  ('WR1', 'Warehouse and Receiving');


INSERT INTO WorksIn_T (EmployeeID, WorkCenterID)
VALUES ('123-44-345', 'SM1');


--list the data in various tables

SELECT * FROM Uses_T;
SELECT * FROM WorksIn_T;
SELECT * FROM WorkCenter_T;
SELECT * FROM DoesBusinessIn_T;
SELECT * FROM EmployeeSkills_T;
SELECT * FROM Supplies_T;
SELECT * FROM ProducedIn_T;
SELECT * FROM OrderLine_T;
SELECT * FROM Product_T;
SELECT * FROM ProductLine_T;
SELECT * FROM Order_T;
SELECT * FROM Salesperson_T;
SELECT * FROM Vendor_T;
SELECT * FROM Skill_T;
SELECT * FROM RawMaterial_T;
SELECT * FROM Territory_T;
SELECT * FROM Employee_T;
SELECT * FROM Customer_T;
