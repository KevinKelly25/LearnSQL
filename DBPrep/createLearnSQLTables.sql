CREATE TABLE IF NOT EXISTS UserData (
  Username                VARCHAR(256) NOT NULL PRIMARY KEY,
  FullName                VARCHAR(256) NOT NULL,
  Password                VARCHAR(256) NOT NULL,
  Email                   VARCHAR(319) NOT NULL CHECK(TRIM(Email) like '_%@_%._%'),
  DateJoined              DATE DEFAULT CURRENT_DATE,
  isTeacher               BOOLEAN DEFAULT FALSE,
  isAdmin                 BOOLEAN DEFAULT FALSE
);

CREATE UNIQUE INDEX idx_Unique_Email ON UserData(LOWER(TRIM(Email)));

CREATE TABLE IF NOT EXISTS Class (
  ClassID                 VARCHAR(60) NOT NULL PRIMARY KEY,
  ClassName               VARCHAR(60),
  Password                VARCHAR(60)
);

CREATE TABLE IF NOT EXISTS Attends (
  ClassID                 VARCHAR(30) NOT NULL REFERENCES Class,
  Username                  VARCHAR(30) NOT NULL REFERENCES UserData,
  isTeacher               BOOLEAN,
  PRIMARY KEY (ClassID, Username)
);
