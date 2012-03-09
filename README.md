# RequireJS for Rails

Integrates [RequireJS](http://requirejs.org/) into the Rails 3 Asset Pipeline.

**UPGRADE NOTES:** Users upgrading within the 0.x series should read the Changes section for relevant usage changes.  We're pushing hard to 1.0, when the configuration and setup details will be declared stable.  Until that time expect some bumps as things bake out.

## Usage

1. Add this to your Rails app's `Gemfile`:

    ```
    gem 'requirejs-rails'
    ```

2. Remove all Sprockets directives such as `//= require jquery` from `application.js` and elsewhere.  Instead establish JavaScript dependencies using AMD-style `define()` and `require()` calls.

3. Use `requirejs_include_tag` at the top-level of your app's layout(s).  Other modules will be pulled in dynamically by `require.js` in development and for production builds optimized by `r.js`.  Here's a basic `app/views/layouts/application.html.erb` modified for `requirejs-rails`:

    ```erb
    <!DOCTYPE html>
    <html>
    <head>
      <title>Frobnitz Online</title>
      <%= stylesheet_link_tag   "application" %>
      <%= requirejs_include_tag "application" %>
      <%= csrf_meta_tags %>
      <meta charset="utf-8">
    </head>
    <body>

    <%= yield %>

    </body>
    </html>
    ```

4. Organize your JavaScript or CoffeeScript code into modules using `define()`:

      ```coffeescript
      # app/assets/javascripts/views/tweet_view.js.coffee

      define ['backbone'], (Backbone) ->
        class TweetView extends Backbone.View
          # ...
      ```

5. Instantiate your app using `require()` from a top-level module such as `application.js`:

      ```coffeescript
      # app/assets/javascripts/application.js.coffee

      require ['jquery', 'backbone', 'TheApp'], ($, Backbone, TheApp) ->

        # Start up the app once the DOM is ready
        $ ->
          window.App = new TheApp()
          Backbone.history.start
            pushState: true
          window.App.start()
      ```

6. When ready, build your assets for production deployment as usual.  `requirejs-rails` defaults to a single-file build of `application.js`.  Additional modules and r.js layered builds may be specified via `config\requirejs.yml`; see the Configuration section below.

    ```rake assets:precompile```

## Configuration

### The Basics

Configuration lives in `config/requirejs.yml`.  These values are inspected and
used by `requirejs-rails` and passed along as configuration for require.js and
`r.js`.  The default configuration declares `application.js` as the sole
top-level module.  This can be overridden by creating
a `config/requirejs.yml`, such as:

```yaml
modules:
  - name: 'mytoplevel'
```

You may pass in [require.js config
options](http://requirejs.org/docs/api.html#config) as needed.  For example,
to add path parameters:

```yaml
paths:
  d3: "d3/d3"
  "d3.time": "d3/d3.time"
```

### Layered builds

Only modules specified in the configuration will be created as build artifacts
by `r.js`.  [Layered r.js
builds](http://requirejs.org/docs/faq-optimization.html#priority) be
configured like so:

```yaml
modules:
  - name: 'appcommon'
  - name: 'page1'
    exclude: ['appcommon']
  - name: 'page2'
    exclude: ['appcommon']
priority: ['appcommon']
```

In this example, only modules `page1` and `page2` are intended for direct
loading via `requirejs_include_tag`. The `appcommon` module contains
dependencies shared by the per-page modules.  As a guideline, each module in
the configuration should be referenced by one of:

- A `requirejs_include_tag` in a template
- Pulled in via a dynamic `require()` call.  Modules which are solely
  referenced by a dynamic `require()` call (i.e. a call not optimized by r.js)
  **must** be specified in the modules section in order to produce a correct
  build.
- Be a common library module like `appcommon`, listed in the `priority` config
  option.

## Advanced features

### Additional data attributes

`requirejs_include_tag` accepts an optional block which should return a hash.
This hash will be used to populate additional `data-...` attributes like so:

```erb
<%= requirejs_include_tag "page1" do |controller|
      { 'foo' => controller.foo,
        'bar' => controller.bar
      }
    end
%>
```

This will generate a script tag like so:

```
<script data-main="/assets/page1.js" data-foo="..." data-bar="..." src="/assets/require.js"></script>
```

## Using AMD libraries

I currently recommend placing your AMD libraries into `vendor/assets/javascripts`.  The needs of a few specific libraries are discussed below.

### jQuery

jQuery users must use jQuery 1.7 or later (`jquery-rails >= 1.0.17`) to use it as an [AMD module](http://wiki.commonjs.org/wiki/Modules/AsynchronousDefinition) with RequireJS.  To use jQuery in a module:

```coffeescript
# app/assets/javascripts/hello.js

define ['jquery'], ($) ->
  (id) ->
    $(id).append('<div>hello!</div>')
```

### Backbone.js

Backbone 0.9.x doesn't support AMD natively.  I recommend the [amdjs
fork of Backbone](https://github.com/amdjs/backbone/) which adds AMD
support and actively tracks mainline.

### Underscore.js

Underscore 1.3.x likewise doesn't have AMD support.  Again, see
the [amdjs fork of Underscore](https://github.com/amdjs/underscore).

## Changes

Usage changes that impact folks upgrading along the 0.x series are
documented here. See [the Changelog](CHANGELOG.md) for other details.

### v0.5.1

- `requirejs_include_tag` now generates a data-main attribute if given an argument, ala:

    ```erb
    <%= requirejs_include_tag "application" %>
    ```

    This usage is preferred to using a separate
    `javascript_include_tag`, which will produce errors from require.js or
    r.js if the included script uses define anonymously, or not at all.

### v0.5.0

- `application.js` is configured as the default top-level module for r.js builds.
- It is no longer necessary or desirable to specify `baseUrl` explicitly in the configuration.
- Users should migrate application configuration previously in `application.js` (ala `require.config(...)`) to `config/requirejs.yml`



## TODOs

Please check out [our GitHub issues page](https://github.com/jwhitley/requirejs-rails/issues)
to see what's upcoming and to file feature requests and bug reports.

----

Copyright 2011 John Whitley.  See the file MIT-LICENSE for terms.
