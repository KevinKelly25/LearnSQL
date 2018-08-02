CREATE TABLE IF NOT EXISTS Users (
  UserID                  VARCHAR(60) NOT NULL PRIMARY KEY,
  FullName                VARCHAR(256) NOT NULL,
  Password                VARCHAR(256) NOT NULL,
  Email                   VARCHAR(319) NOT NULL CHECK(TRIM(Email) like '_%@_%._%'),
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE
);

CREATE

Create Table IF NOT EXISTS Class (
  ClassID                 VARCHAR(60) NOT NULL PRIMARY KEY,
  ClassName               VARCHAR(60),
  Password                VARCHAR(60)
);

Create Table IF NOT EXISTS Attends (
  ClassID                 VARCHAR(30) NOT NULL REFERENCES Class,
  UserID                  VARCHAR(30) NOT NULL REFERENCES Users,
  isTeacher               BOOLEAN,
  PRIMARY KEY (ClassID, UserID)
);

Create Table IF NOT EXISTS test (
  UserID                  VARCHAR(30) NOT NULL PRIMARY KEY,
  Email                   VARCHAR(60) NOT NULL
);
