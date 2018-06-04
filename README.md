# Bootstrap 4.1 Starter Pack

**Includes complete Bootstrap 4.1.0 dev environment with Gulp and Sass**

## Install Dependencies

`npm install`
## Compile Sass and Run Dev Server

`npm start`


**Note: Browser-Sync is set with default browser as Firefox.**

`gulp.task("serve", ["sass"], function() {
	browserSync.init({
		server: "./src",
		browser: "firefox"
	});`

  **Remove:**  , browser: "firefox"* to use your default browser or set to a browser of your choice.