(function(appConfig) {

  'use strict';

  // *** main dependencies *** //
  const path = require('path');
  const cookieParser = require('cookie-parser');
  const bodyParser = require('body-parser');
  const session = require('express-session');
  const flash = require('connect-flash');
  const morgan = require('morgan');
  const nunjucks = require('nunjucks'); // might not need
  const passport = require('passport');

  // added this
  const express = require('express');
  const exphbs = require('express-handlebars');
  const nodemailer = require('nodemailer');
  const hbs = require('hbs');
  
  // end of added this
  
  // *** view folders *** //
  const viewFolders = [
    path.join(__dirname, '..', 'views')
  ];

  // *** load environment variables *** //
  require('dotenv').config();

  appConfig.init = function(app, express) {

    // added this 
    app.set('view engine', 'html');
    app.engine('html', require('hbs').__express);
    // end of added this


    // *** app middleware *** //
    if (process.env.NODE_ENV !== 'test') {
      app.use(morgan('dev'));
    }

    app.use(cookieParser());
    app.use(bodyParser.json());
    app.use(bodyParser.urlencoded({ extended: false }));
    // uncomment if using express-session
    // TODO: change secret to process.env.SECRET_KEY
    app.use(session({
      secret: 'anything',
      resave: false,
      saveUninitialized: true
    }));
    app.use(passport.initialize());
    app.use(passport.session());
    app.use(flash());
    app.use(express.static(path.join(__dirname, '..', '..', 'client')));

    // added this
    app.get('/', (req, res) => {
      console.log('app.get initialized...');
      res.render(path.join(__dirname, '..', '..', 'client', 'views'));
    });
    
    app.post('/send', (req, res) => {
      console.log('app.post is working')
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
    // end of added this

  };

})(module.exports);
