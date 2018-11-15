## Database Source

_Author: Christopher Innaco_

### Script-level Significance

This directory includes the SQL and PL/pgSQL scripts which perform the following actions:
* Create the LearnSQL schema and associated objects based on the conceptual and logical schema such as:
    * Tables
    * Views
    * Indexes
    * Functions related to
        * User management
        * Student management
        * Class management
    * Extensions
        * `dblink` for cross database queries
        * `pgcrypto` for password hashing and salting

* Create PostgreSQL server-level roles
* Create and populate the Questions database with a sample schema and data based on the fictitious Pine Valley Furniture Company (PVFC)
    * The current iteration of the product does not interact with this database with the exception of the exercises on the `LearnSQL\src\webapp\client\views\learn\select.html` page. Further expansion is not anticipated in the scope of the Fall 2018 semester.

### Product-level Conceptual Significance

The LearnSQL database serves as the master database which presides over numerous [ClassDB](https://github.com/DASSL/ClassDB)-enabled databases. The ClassDB databases serve as a sandbox for students to experiment with relational data within the context of a class. The LearnSQL database retains records of these class specific databases with descriptors such as which teachers and students are members, to name a few. These details are kept on the LearnSQL database to present a fluent, consistent and concise user interface through a web server. To enforce these requirements, LearnSQL maintains several roles and defines the permissions each role holds.

* Roles: Each role has the ability to inherit the permissions of the role preceding
    * Student
        * A user currently enrolled in one or more classes
    * Teacher
        * A user who instructs one or more classes
    * Administrator
        * A user who holds the authorization to 
            * Create and drop all schema objects for any given class database
            * Enroll and drop students directly
            * Create and drop classes
            * Verify the functionality of the web application through the UI





