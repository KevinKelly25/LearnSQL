Create Table IF NOT EXISTS Users (
  UserID			   VARCHAR(30) NOT NULL PRIMARY KEY,
  FullName       VARCHAR(60) NOT NULL,
  Password       VARCHAR(60) NOT NULL,
  Email		       VARCHAR(60) NOT NULL,
  DateJoined	   DATE DEFAULT CURRENT_DATE,
  isTeacher      BOOLEAN DEFAULT FALSE
  isAdmin      BOOLEAN DEFAULT FALSE
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
