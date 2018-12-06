## Web Application Source
_Author: Christopher Innaco_

### Overview

This directory contains the client and server code which comprises the front-end user interface and middleware. The user interface is powered by [HTML5](https://en.wikipedia.org/wiki/HTML5), [Bootstrap](https://getbootstrap.com/) and [AngularJS](https://angular.io/). Bootstrap supplies predefined CSS classes which decrease the time required to develop professional-looking webpages. AngularJS provides a powerful framework which enables dynamic HTML without direct manipulation of the Document Object Model (DOM). All of these technologies run on top of a Node.JS Express web server. 

### High-level description

The following describes how a user's interaction with the web application causes data transference  through the three-tiered architecture:

* A user has been given a classID and classPassword for a class for which they wish to enroll
* After the user signs into the website, they navigate to the `Classes` tab on the navigation bar
* The user clicks the `Join Class` button and is presented with a modal to enter the classID and classPassword
* Assuming the information given was correct, the user is now considered a student and is shown a table with the new class as a listing with relevant data such as the class name, section, times, etc...

Here is the process explained in technical terms of the structure of the product:

* The `/views/controlPanels/joinClass.html` page is loaded from the webserver which uses the `studentCtrl` AngularJS controller
* When the `Join Class` button is clicked, AngularJS reveals the modal using the `ng-show` attribute.
* When the user clicks the `Join Class` button within the modal after entering the required information, the controller sends an HTTP `POST` request using the `/student/joinClass` route
* This route calls the middleware `addStudent()` function which resides in the `studentControlPanel.js` file
* In this function, a call to the `LearnSQL.joinClass()` PL/pgSQL function is made using the class information specified in the modal and using database credentials found in the `.env` file.
* Based on the result of the query, a success message or error code is returned and is displayed in the modal.
* If successful, the modal closes and the page is redirected to `/views/controlPanels/studentClasses.html`






