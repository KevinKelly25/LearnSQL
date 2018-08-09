const gulp = require("gulp");
const browserSync = require("browser-sync").create();
const sass = require("gulp-sass");

// ------------------------------------------
//added this to the gulpfile.js
const express = require('express');
const bodyParser = require('body-parser');
const exphbs = require('express-handlebars');
const path = require('path');
const nodemailer = require('nodemailer');
const hbs = require('hbs');
const app = express();
// ------------------------------------------

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

// ----------------------------------------------------------------------------------- 
// added this to gulpfile.js
app.set('views', path.join(__dirname, '/client/views'));
app.set('view engine', 'html');
app.engine('html', require('hbs').__express);

// static folder
app.use(express.static(__dirname + '/client'));

// body parser middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.get('/', (req, res) => {
    res.render('contact');
});

app.post('/send', (req, res) => {
    const output = `
        <p>You have a new app request</p>
        <h3>app Details</h3>
        <ul>
            <li>First Name: ${req.body.firstName}</li>
            <li>Last Name: ${req.body.lastName}</li>
            <li>Email: ${req.body.email}</li>
            <li>Phone Number: ${req.body.phoneNumber}</li>
        </ul>
        <h3>Message</h3>
        <p>${req.body.message}</p>
    `;

    let transporter = nodemailer.createTransport({
        host: 'smtp-mail.outlook.com',
        port: 587,
        secure: false, // true for 465, false for other ports
        auth: {
            user: 'test123203@outlook.com', // generated ethereal user
            pass: 'testing123!' // generated ethereal password
        },
        tls:{
            rejectUnauthorized:false
        }
    });

    // setup email data with unicode symbols
    let mailOptions = {
        from: '"Nodemailer app 👻" <test123203@outlook.com>', // sender address
        to: 'testacct123203@gmail.com', // list of receivers
        subject: 'Node app Request', // Subject line
        text: 'Hello world?', // plain text body
        html: output // html body
    };

    // send mail with defined transport object
    transporter.sendMail(mailOptions, (error, info) => {
        if (error) {
            return console.log(error);
        }
        console.log('Message sent: %s', info.messageId);
        console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));

        res.render('contact', {msg:'Email has been sent'});
    });
});

// app.listen(3000);
// -------------------------------------------------------------------------------------