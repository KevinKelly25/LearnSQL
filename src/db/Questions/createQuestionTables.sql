--temporary create scripts taken from the textbox. Will need to add our own

CREATE TABLE IF NOT EXISTS Customer_T
(
 CustomerID          NUMERIC(11,0) NOT NULL,
 CustomerName        VARCHAR(25) NOT NULL,
 CustomerAddress     VARCHAR(30),
 CustomerCity        VARCHAR(20),
 CustomerState       CHAR(2),
 CustomerPostalCode  VARCHAR(10),
 CONSTRAINT Customer_PK PRIMARY KEY (CustomerID)
);



CREATE TABLE IF NOT EXISTS Territory_T
(
 TerritoryID         NUMERIC(11,0) NOT NULL,
 TerritoryName       VARCHAR(50),
 CONSTRAINT Territory_PK PRIMARY KEY (TerritoryID)
);



CREATE TABLE IF NOT EXISTS DoesBusinessIn_T
(
 CustomerID          NUMERIC(11,0) NOT NULL,
 TerritoryID         NUMERIC(11,0) NOT NULL,
 CONSTRAINT DoesBusinessIn_PK PRIMARY KEY (CustomerID, TerritoryID),
 CONSTRAINT DoesBusinessIn_FK1 FOREIGN KEY (CustomerID) REFERENCES Customer_T(CustomerID),
 CONSTRAINT DoesBusinessIn_FK2 FOREIGN KEY (TerritoryID) REFERENCES Territory_T(TerritoryID)
);



CREATE TABLE IF NOT EXISTS Employee_T
(
 EmployeeID          VARCHAR(10) NOT NULL,
 EmployeeName        VARCHAR(25),
 EmployeeAddress     VARCHAR(30),
 EmployeeBirthDate   DATE,
 EmployeeCity        VARCHAR(20),
 EmployeeState       CHAR(2),
 EmployeeZipCode     VARCHAR(10),
 EmployeeDateHired   DATE,
 EmployeeSupervisor  VARCHAR(10),
 CONSTRAINT Employee_PK PRIMARY KEY (EmployeeID)
);



CREATE TABLE IF NOT EXISTS Skill_T
(
 SkillID             VARCHAR(12) NOT NULL,
 SkillDescription    VARCHAR(30),
 CONSTRAINT Skill_PK PRIMARY KEY (SkillID)
);



CREATE TABLE IF NOT EXISTS EmployeeSkills_T
(
 EmployeeID          VARCHAR(10) NOT NULL,
 SkillID             VARCHAR(12) NOT NULL,
 CONSTRAINT EmployeeSkills_PK PRIMARY KEY (EmployeeID, SkillID),
 CONSTRAINT EmployeeSkills_FK1 FOREIGN KEY (EmployeeID) REFERENCES Employee_T(EmployeeID),
 CONSTRAINT EmployeeSkills_FK2 FOREIGN KEY (SkillID) REFERENCES Skill_T(SkillID)
);



CREATE TABLE IF NOT EXISTS Order_T
(
 OrderID             NUMERIC(11,0) NOT NULL,
 CustomerID          NUMERIC(11,0),
 OrderDate           DATE DEFAULT CURRENT_DATE,
 CONSTRAINT Order_PK PRIMARY KEY (OrderID),
 CONSTRAINT Order_FK1 FOREIGN KEY (CustomerID) REFERENCES Customer_T(CustomerID)
);



CREATE TABLE IF NOT EXISTS WorkCenter_T
(
 WorkCenterID         VARCHAR(12)NOT NULL,
 WorkCenterLocation   VARCHAR(30),
 CONSTRAINT WorkCenter_PK PRIMARY KEY (WorkCenterID)
);



CREATE TABLE IF NOT EXISTS ProductLine_T
(
 ProductLineID       NUMERIC(11,0) NOT NULL,
 ProductLineName      VARCHAR(50),
 CONSTRAINT ProductLine_PK PRIMARY KEY (ProductLineID)
);



CREATE TABLE IF NOT EXISTS Product_T
(
 ProductID           NUMERIC(11,0) NOT NULL,
 ProductLineID       NUMERIC(11,0),
 ProductDescription  VARCHAR(50),
 ProductFinish       VARCHAR(20),
 ProductStandardPrice DECIMAL(6,2),
 CONSTRAINT Product_PK PRIMARY KEY (ProductID),
 CONSTRAINT Product_FK1 FOREIGN KEY (ProductLineID) REFERENCES ProductLine_T(ProductLineID)
);



CREATE TABLE IF NOT EXISTS ProducedIn_T
(
 ProductID 	  NUMERIC(11,0) NOT NULL,
 WorkCenterID        VARCHAR(12) NOT NULL,
 CONSTRAINT ProducedIn_PK PRIMARY KEY (ProductID, WorkCenterID),
 CONSTRAINT ProducedIn_FK1 FOREIGN KEY (ProductID) REFERENCES Product_T(ProductID),
 CONSTRAINT ProducedIn_FK2 FOREIGN KEY (WorkCenterID) REFERENCES WorkCenter_T(WorkCenterID)
);




CREATE TABLE IF NOT EXISTS OrderLine_T
(
 OrderID            NUMERIC(11,0) NOT NULL,
 ProductID           NUMERIC(11,0) NOT NULL,
 OrderedQuantity     NUMERIC(11,0),
 CONSTRAINT OrderLine_PK PRIMARY KEY (OrderID, ProductID),
 CONSTRAINT OrderLine_FK1 FOREIGN KEY (OrderID) REFERENCES Order_T(OrderID),
 CONSTRAINT OrderLine_FK2 FOREIGN KEY (ProductID) REFERENCES Product_T(ProductID)
);




CREATE TABLE IF NOT EXISTS RawMaterial_T
(
 MaterialID          VARCHAR(12) NOT NULL,
 MaterialName        VARCHAR(30),
 MaterialStandardCost DECIMAL(6,2),
 UnitOfMeasure       VARCHAR(10),
 CONSTRAINT RawMaterial_PK PRIMARY KEY (MaterialID)
);


CREATE TABLE IF NOT EXISTS Salesperson_T
(
 SalespersonID       NUMERIC(11,0) NOT NULL,
 SalespersonName     VARCHAR(25),
 SalespersonPhone    VARCHAR(50),
 SalespersonFax      VARCHAR(50),
 TerritoryID         NUMERIC(11,0),
 CONSTRAINT Salesperson_PK PRIMARY KEY (SalesPersonID),
 CONSTRAINT Salesperson_FK1 FOREIGN KEY (TerritoryID) REFERENCES Territory_T(TerritoryID)
);



CREATE TABLE IF NOT EXISTS Vendor_T
(
 VendorID            NUMERIC(11,0) NOT NULL,
 VendorName          VARCHAR(25),
 VendorAddress       VARCHAR(30),
 VendorCity          VARCHAR(20),
 VendorState         CHAR(2),
 VendorZipcode       VARCHAR(50),
 VendorFax           VARCHAR(10),
 VendorPhone         VARCHAR(10),
 VendorContact       VARCHAR(50),
 VendorTaxID         VARCHAR(50),
 CONSTRAINT Vendor_PK PRIMARY KEY (VendorID)
);


CREATE TABLE IF NOT EXISTS Supplies_T
(
 VendorID            NUMERIC(11,0) NOT NULL,
 MaterialID          VARCHAR(12) NOT NULL,
 SuppliesUnitPrice   DECIMAL(6,2),
 CONSTRAINT Supplies_PK PRIMARY KEY (VendorID, MaterialID),
 CONSTRAINT Supplies_FK1 FOREIGN KEY (MaterialId) REFERENCES RawMaterial_T(MaterialID),
 CONSTRAINT Supplies_FK2 FOREIGN KEY (VendorID) REFERENCES Vendor_T(VendorID)
);



CREATE TABLE IF NOT EXISTS Uses_T
(
 ProductID           NUMERIC(11,0) NOT NULL,
 MaterialID          VARCHAR(12)NOT NULL,
 GoesIntoQuantity    INTEGER,
 CONSTRAINT Uses_PK PRIMARY KEY (ProductID, MaterialID),
 CONSTRAINT Uses_FK1 FOREIGN KEY (ProductID) REFERENCES Product_T(ProductID),
 CONSTRAINT Uses_FK2 FOREIGN KEY (MaterialID) REFERENCES RawMaterial_T(MaterialID)
);



CREATE TABLE IF NOT EXISTS WorksIn_T
(
 EmployeeID          VARCHAR(10) NOT NULL,
 WorkCenterID        VARCHAR(12) NOT NULL,
 CONSTRAINT WorksIn_PK PRIMARY KEY (EmployeeID, WorkCenterID),
 CONSTRAINT WorksIn_FK1 FOREIGN KEY (EmployeeID) REFERENCES Employee_T(EmployeeID),
 CONSTRAINT WorksIn_FK2 FOREIGN KEY (WorkCenterID) REFERENCES WorkCenter_T(WorkCenterID)
);
