const gulp = require("gulp");
const browserSync = require("browser-sync").create();
const sass = require("gulp-sass");

// Compile Sass & Inject Into Browser
gulp.task("sass", function() {
	return gulp
    .src(["node_modules/bootstrap/scss/bootstrap.scss", "client/scss/*.scss"])
    .pipe(sass().on("error", sass.logError))
    .pipe(gulp.dest("client/stylesheets"))
	.pipe(browserSync.stream());
});

// Move JS Files to src/js
gulp.task("js", function() {
	return gulp
		.src([
			"node_modules/bootstrap/dist/js/bootstrap.min.js",
			"node_modules/jquery/dist/jquery.min.js",
			"node_modules/popper.js/dist/umd/popper.min.js"
		])
		.pipe(gulp.dest("client/javascripts"))
		.pipe(browserSync.stream());
});

gulp.task('default' , [ 'build','watch','connect'] , function(){
  express;
});

// Move Fonts to src/fonts
gulp.task("fonts", function() {
	return gulp
		.src("node_modules/font-awesome/fonts/*")
		.pipe(gulp.dest("client/fonts"));
});

// Move Font Awesome CSS to src/css
gulp.task("fa", function() {
	return gulp
		.src("node_modules/font-awesome/css/font-awesome.min.css")
		.pipe(gulp.dest("client/stylesheets"));
});

gulp.task("default", ["js",'sass', "fa", "fonts"]);
