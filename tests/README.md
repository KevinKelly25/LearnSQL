## Tests

_Author: Christopher Innaco_

This directory includes the PL/pgSQL scripts and JavaScript files whose purpose is to perform automated testing on the functionality of the product. Since the core of the operations critical to the product reside in the LearnSQL database, it is appropriate to have comprehensive tests which encompass the following objectives.

### Current Test Script Design
* Sanity/smoke tests
    * The test scripts ensure that after a function is called, the effects of the expected change are present. The JavaScript test files validate the accessibility of database functions in addition to UI specific checks. Before termination of the script, the results of the test are reported to the user for the identification of faults.
* Security/Role tests
    * The test scripts perform checks to make sure only users with the required privilege are able to execute functions assigned to their role/group.
* Regression tests
    * When testing for compatibility between branches in a pull request, these tests will report errors which may be a result of changes in the branch requesting to be merged.

### Anticipated Test Script Design
* Load testing
    * Planning for the [CSCU](http://www.ct.edu/)-wide deployment of LearnSQL's underlying technology, [ClassDB](https://github.com/DASSL/ClassDB), means that LearnSQL must scale to the same degree as ClassDB in order to become a viable supplementary product. A general figure for scalability is 4,000 users and a proportional number of classes.
* Usability testing
    * Due to the educational nature of this web application, it is critical to evaluate the effectiveness of the layout and function of the application to enhance the learning process. A combination of various testing methods such as using focus groups, A/B testing, surveys and beta testing will benefit the overall design of the product.
* More In-depth Round-trip testing
    * Test scripts should exist at each tier of the application to verify the functionality of the individual components. This will also aid in determining which tier a given error originates from.


