Create Table IF NOT EXISTS User (
  UserID			   VARCHAR(30) NOT NULL PRIMARY KEY,
  FullName       VARCHAR(60),
  Password       VARCHAR(60),
  Email		       VARCHAR(60),
  DateJoined	   DATE,
  isTeacher      BOOLEAN
);

Create Table IF NOT EXISTS Class (
  ClassID			   VARCHAR(30) NOT NULL PRIMARY KEY,
  ClassName      VARCHAR(60),
  Password       VARCHAR(60)
);

Create Table IF NOT EXISTS Attends (
  ClassID			   VARCHAR(30) NOT NULL REFERENCES Class,
  UserID			   VARCHAR(30) NOT NULL PRIMARY KEY,
  isTeacher      BOOLEAN,
  PRIMARY KEY (ClassID, UserID)
);
