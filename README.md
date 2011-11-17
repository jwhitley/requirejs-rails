# RequireJS for Rails

Integrates [RequireJS](http://requirejs.org/) into the Rails 3 Asset Pipeline.

## Usage

1. Add this to your Rails app's `Gemfile`:

    ```
    gem 'requirejs-rails'
    ```

2. Your `application.js` file should contain just this snippet. The rest of your JavaScript or CoffeeScript code should be pulled in via RequireJS, including jQuery.

    ```javascript
    //= require require

    require.config({
      baseUrl: "/assets"
    });
    ```

3. Add any additional [config options](http://requirejs.org/docs/api.html#config) you need to the above code, e.g. `paths`.

4. Organize your JavaScript or CoffeeScript code into modules using `define()`:

      ```coffeescript
      # app/assets/javascripts/views/tweet_view.js.coffee

      define ['backbone'], (Backbone) ->
        class TweetView extends Backbone.View
          # ...
      ```

5. Instantiate your app using `require()` from a top-level script such as `application.js` or a controller-specific file ala `mycontroller.js.coffee`:

      ```coffeescript
      # app/assets/javascripts/mycontroller.js.coffee

      require ['jquery', 'backbone', 'TheApp'], ($, Backbone, TheApp) ->

        # Start up the app once the DOM is ready
        $ ->
          window.App = new TheApp()
          Backbone.history.start
            pushState: true
          window.App.start()
      ```


## Using AMD libraries

I currently recommend placing your AMD libraries into `vendor/assets/javascripts`.  The needs of a few specific libraries are discussed below.

### jQuery

jQuery users must use jQuery 1.7 or later (`jquery-rails >= 1.0.17`) to use it as an [AMD module](http://wiki.commonjs.org/wiki/Modules/AsynchronousDefinition) with RequireJS.  The boilerplate in `application.js` remains unchanged.  To use jQuery in a module:

```coffeescript
# app/assets/javascripts/hello.js

define ['jquery'], ($) ->
  (id) ->
    $(id).append('<div>hello!</div>')
```

### Backbone.js

Backbone AMD support is underway in documentcloud/backbone#710.  In the meantime, you can download [Backbone 0.5.3 with AMD support](https://github.com/jrburke/backbone/raw/optamd3/backbone.js) from [jrburke's optamd3 branch](https://github.com/jrburke/backbone/tree/optamd3).  Backbone's module name is `backbone`.

### Underscore.js

Underscore version 1.2.2 or later has integrated AMD support.  Get it from [Underscore.js' homepage](http://documentcloud.github.com/underscore/). Underscore's module name is `underscore`.

## Changes

See [the Changelog](CHANGELOG.md) for recent updates

## TODOs

- Sample app, including jQuery usage
- Support RequireJS precompilation via r.js (see issue #1)
- Generator and/or template support.. ?

----

Copyright 2011 John Whitley.  See the file MIT-LICENSE for terms.
