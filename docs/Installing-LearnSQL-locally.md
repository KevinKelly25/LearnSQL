# LearnSQL Server Setup (localhost)
_Author: Christopher Innaco_

## Step 1: Install [PostgreSQL](https://www.postgresql.org/) 
The recommended interactive installer is distributed by EnterpriseDB and can be found [here](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads). LearnSQL is designed using versions 9.6 and 10.4, on a Windows 10 v1803 x86-64 environment, but may work with older versions and other platforms.

* Run the installer as an administrator if not prompted.
* The installation directory can be left as the default, although this may be changed with no side-effects.
* Leave the default selections for components.
* The default data directory can be left as the default, although if the installation directory was changed, append to it a child `\data` directory.
* Set the password to: `password`.
* Set the server to listen to port `5432`, which is the default.
* The locale can be left as the default.
* When the files have completed installing, the installer can be closed without launching StackBuilder. (An unnecessary utility)

## Step 2: Create the LearnSQL databases
* Open an administrator Command Prompt or Powershell and navigate to the installation directory for PostgreSQL. 
     Example installation directory: `C:\ Program Files\PostgreSQL\10\bin`
* Type, `psql -U postgres`, where `postgres` is the default user.
* Enter the password defined during the installation process. Ignore errors regarding the incorrect rendering of 8-bit characters.
* Now type the following statements to create the databases:
*    `CREATE DATABASE learnsql;`
*    `CREATE DATABASE questions;`
* Switch to the `learnsql` database just created using `\c learnsql`.
* Create the tables for this database using: `\i 'C:/Users/<User>/…/LearnSQL/DBPrep/createLearnSQLTables.sql';` Note the use of forward slashes and single quotes.
* Switch to the `questions` database using `\c questions`.
* Create the tables for this database using: `\i 'C:/Users/<User>/…/LearnSQL/DBPrep/createQuestionTables.sql';`
* Populate the tables using: `\i 'C:/Users/<User>/…/LearnSQL/DBPrep/populate.sql';`

## Step 3: Install [ClassDB](https://github.com/DASSL/ClassDB)
* Follow the **Full Installation** process found on the ClassDB GitHub found [here](https://github.com/DASSL/ClassDB/wiki/Setup) and substitute `<databaseName>` with `classdb_template`.
* Additionally, run the following script while connected to the `classdb_template` database: `\i 'C:/Users/<User>/…/LearnSQL/DBPrep/ClassDBAdditions.sql';`

## Step 4: Install Node.js
* The installer can be found [here](https://nodejs.org/en/download/) and will include `npm`. Use the installer defaults.

## Step 5: Install the Web Server
* Open a Command Prompt or Powershell as administrator
* Navigate to the root of the LearnSQL directory and type `npm install`.
* Next type `npm start`.
* If errors regarding missing bindings for Sass are encountered, type: `npm rebuild node-sass --force`, then `npm install` and finally `npm start`.

## Step 6: Launch the Web Server
* Open a web browser and navigate to `http://localhost:3000/` and the LearnSQL homepage should be displayed.
