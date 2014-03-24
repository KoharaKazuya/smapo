// Start sails and pass it command line arguments
require('./node_modules/sails/node_modules/coffee-script');
require('sails').lift(require('optimist').argv);
