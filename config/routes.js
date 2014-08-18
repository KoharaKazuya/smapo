/**
 * Routes
 *
 * Sails uses a number of different strategies to route requests.
 * Here they are top-to-bottom, in order of precedence.
 *
 * For more information on routes, check out:
 * http://sailsjs.org/#documentation
 */



/**
 * (1) Core middleware
 *
 * Middleware included with `app.use` is run first, before the router
 */


/**
 * (2) Static routes
 *
 * This object routes static URLs to handler functions--
 * In most cases, these functions are actions inside of your controllers.
 * For convenience, you can also connect routes directly to views or external URLs.
 *
 */

module.exports.routes = {

  // By default, your root route (aka home page) points to a view
  // located at `views/home/index.ejs`
  //
  // (This would also work if you had a file at: `/views/home.ejs`)
  '/': {
    controller: 'HomeController',
    action: 'index'
  },

  '/user/new': {
    view: 'user/new'
  },

  '/auth/signin': {
    view: 'auth/signin'
  },

  '/profile/:id': {
    view: 'profile'
  },

  '/setting/profile': {
    view: 'setting/profile'
  },
  '/setting/service': {
    view: 'setting/service'
  },
  '/setting/account': {
    view: 'setting/account'
  },
  '/setting/follow': {
    view: 'setting/follow'
  },

  '/hello': {
    view: 'support/hello'
  },

  '/help/usage': {
    view: 'support/usage'
  },
  '/help/hatenablog': {
    view: 'support/hatenablog'
  },
  '/help/zusaar': {
    view: 'support/zusaar'
  },
  '/help/twitch': {
    view: 'support/twitch'
  },
  '/help/twitter': {
    view: 'support/twitter'
  },
  '/help/youtube': {
    view: 'support/youtube'
  },

  '/userlist': {
    view: 'userlist/index'
  },
  '/userlist/ssb': {
    view: 'userlist/ssb'
  },
  '/userlist/ssbm': {
    view: 'userlist/ssbm'
  },
  '/userlist/ssbb': {
    view: 'userlist/ssbb'
  },
  '/userlist/ssb4': {
    view: 'userlist/ssb4'
  },

  '/support/getnoemail': {
    view: 'support/getnoemail'
  },
  '/support/forgotpassword': {
    view: 'support/forgotpassword'
  },
  '/support/resetpassword': {
    view: 'support/resetpassword'
  },
  '/support/report': {
    view: 'support/report'
  },
  '/support/brand': {
    view: 'support/brand'
  },

  '/news/blog': {
    view: 'news/blog'
  },
  '/news/event': {
    view: 'news/event'
  },
  '/news/live': {
    view: 'news/live'
  },
  '/news/flash': {
    view: 'news/flash'
  },
  '/news/video': {
    view: 'news/video'
  },
  '/news/all': {
    view: 'news/all/index'
  },
  '/news/all/blog': {
    view: 'news/all/blog'
  },
  '/news/all/event': {
    view: 'news/all/event'
  },
  '/news/all/live': {
    view: 'news/all/live'
  },
  '/news/all/flash': {
    view: 'news/all/flash'
  },
  '/news/all/video': {
    view: 'news/all/video'
  },

  '/notification/index': {
    view: 'notification/index'
  },
  '/notification/new': {
    view: 'notification/new'
  },

  /*
  // But what if you want your home page to display
  // a signup form located at `views/user/signup.ejs`?
  '/': {
    view: 'user/signup'
  }


  // Let's say you're building an email client, like Gmail
  // You might want your home route to serve an interface using custom logic.
  // In this scenario, you have a custom controller `MessageController`
  // with an `inbox` action.
  '/': 'MessageController.inbox'


  // Alternatively, you can use the more verbose syntax:
  '/': {
    controller: 'MessageController',
    action: 'inbox'
  }


  // If you decided to call your action `index` instead of `inbox`,
  // since the `index` action is the default, you can shortcut even further to:
  '/': 'MessageController'


  // Up until now, we haven't specified a specific HTTP method/verb
  // The routes above will apply to ALL verbs!
  // If you want to set up a route only for one in particular
  // (GET, POST, PUT, DELETE, etc.), just specify the verb before the path.
  // For example, if you have a `UserController` with a `signup` action,
  // and somewhere else, you're serving a signup form looks like:
  //
  //        <form action="/signup">
  //            <input name="username" type="text"/>
  //            <input name="password" type="password"/>
  //            <input type="submit"/>
  //        </form>

  // You would want to define the following route to handle your form:
  'post /signup': 'UserController.signup'


  // What about the ever-popular "vanity URLs" aka URL slugs?
  // (you might remember doing this with `mod_rewrite` in Apache)
  //
  // This is where you want to set up root-relative dynamic routes like:
  // http://yourwebsite.com/twinkletoez
  //
  // NOTE:
  // You'll still want to allow requests through to the static assets,
  // so we need to set up this route to ignore URLs that have a trailing ".":
  // (e.g. your javascript, CSS, and image files)
  'get /*(^.*)': 'UserController.profile'

  */
};



/**
 * (3) Action blueprints
 * These routes can be disabled by setting (in `config/controllers.js`):
 * `module.exports.controllers.blueprints.actions = false`
 *
 * All of your controllers ' actions are automatically bound to a route.  For example:
 *   + If you have a controller, `FooController`:
 *     + its action `bar` is accessible at `/foo/bar`
 *     + its action `index` is accessible at `/foo/index`, and also `/foo`
 */


/**
 * (4) Shortcut CRUD blueprints
 *
 * These routes can be disabled by setting (in config/controllers.js)
 *          `module.exports.controllers.blueprints.shortcuts = false`
 *
 * If you have a model, `Foo`, and a controller, `FooController`,
 * you can access CRUD operations for that model at:
 *      /foo/find/:id?  ->  search lampshades using specified criteria or with id=:id
 *
 *      /foo/create     ->  create a lampshade using specified values
 *
 *      /foo/update/:id ->  update the lampshade with id=:id
 *
 *      /foo/destroy/:id    ->  delete lampshade with id=:id
 *
 */

/**
 * (5) REST blueprints
 *
 * These routes can be disabled by setting (in config/controllers.js)
 *      `module.exports.controllers.blueprints.rest = false`
 *
 * If you have a model, `Foo`, and a controller, `FooController`,
 * you can access CRUD operations for that model at:
 *
 *      get /foo/:id?   ->  search lampshades using specified criteria or with id=:id
 *
 *      post /foo       -> create a lampshade using specified values
 *
 *      put /foo/:id    ->  update the lampshade with id=:id
 *
 *      delete /foo/:id ->  delete lampshade with id=:id
 *
 */

/**
 * (6) Static assets
 *
 * Flat files in your `assets` directory- (these are sometimes referred to as 'public')
 * If you have an image file at `/assets/images/foo.jpg`, it will be made available
 * automatically via the route:  `/images/foo.jpg`
 *
 */



/**
 * (7) 404 (not found) handler
 *
 * Finally, if nothing else matched, the default 404 handler is triggered.
 * See `config/404.js` to adjust your app's 404 logic.
 */
