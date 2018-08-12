// added this
const express = require('express');
const bodyParser = require('body-parser');
const cons = require('consolidate');
const exphbs = require('express-handlebars'); // To use in context of ExpressJS
const path = require('path');
const nodemailer = require('nodemailer'); // Use this module to allow easy as cake email sending
const hbs = require('hbs');

const app = express();

app.set('views', path.join(__dirname, '../../client/views'));

// To use a different extension other than .hbs or .handlebars (i.e. html) for our template file
app.set('view engine', 'html');
app.engine('html', require('hbs').__express);

// static folder
app.use(express.static(__dirname + '../../client/views'));

// body parser middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

app.get('/', (req, res) => {
    console.log("hello from CONTACT PAGE!!!");
    // renders the app.html file (note: extension not needed)
    res.render(path.join(__dirname, '..', '..', 'client', 'views', 'contact'));
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
        host: 'smtp-mail.outlook.com', // host for outlook mail
        port: 587,
        secure: false, // true for 465, false for other ports
        auth: {
            user: 'mtorr203@outlook.com', 
            pass: '88521134Mmfour' 
        },
        tls:{
            // rejectUnauthorized:false will probably need to be changed for production because
            // it can leave you vulnerable to MITM attack - secretly relays and alters the 
            // communication betwee two parties.
            rejectUnauthorized:false
        }
    });

    // setup email data with unicode symbols
    let mailOptions = {
        from: '"Nodemailer app 👻" <mtorr203@outlook.com>', // sender address
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

app.listen(3000, () => console.log('Server started...'));