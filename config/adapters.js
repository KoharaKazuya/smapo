module.exports.adapters = {

  // If you leave the adapter config unspecified
  // in a model definition, 'default' will be used.
  'default': (process.env.NODE_ENV == 'production') ? 'mongo' : 'disk',

  // Persistent adapter for DEVELOPMENT ONLY
  // (data is preserved when the server shuts down)
  disk: {
    module: 'sails-disk'
  },

  mongo: {
    module: 'sails-mongo',
    url: process.env.MONGOLAB_URI
  }

};
