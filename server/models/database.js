//will eventually be used to create all tables and populate
const pg = require('pg');
const connectionString = 'postgres://postgres:password@localhost:5432/WCDB';

const client = new pg.Client(connectionString);
client.connect();
const query = client.query(
  'Create Table IF NOT EXISTS Users (ID VARCHAR(30), Password    VARCHAR(60), Email		VARCHAR(60), DateJoined	DATE)');
query.on('end', () => { client.end(); });
