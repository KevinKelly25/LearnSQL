This is a checklist of automated and manual tests that need to be run for each PR before approving any PR

### Authentication
- [ ] Log in with a student, teacher and admin account.
- [ ] Register new user (Try to log in without validation, validate email and log in)
- [ ] Reset password
### Unit Tests
- [ ] Log in as admin and run all automated tests.
### Teacher
- [ ] Add/remove students
- [ ] Add/remove classes
- [ ] Check class and student lists
- [ ] Go into database and check that all access privileges are restored and above tests are shown in the database
### Student
- [ ] Join classes
- [ ] Check class and student tables
- [ ] Go into database and check that above tests are shown in the database
### Questions
- [ ] Make sure that on `select.html` the correct and wrong answer to questions gives correct response
### Logging
- [ ] Check to make sure no errors that were not expected were thrown
