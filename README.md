# RequireJS for Rails

Integrates [RequireJS](http://requirejs.org/) into the Rails 3 Asset Pipeline.

## Usage

1. `gem install requirejs-rails`

2. Your `application.js` file should contain just this snippet. The rest of your JavaScript or CoffeeScript code should be pulled in via RequireJS, including jQuery.

    ```
    //= require require

    require.config({
      baseUrl: "/assets"
    });
    ```

3. Add any additional config directives you need to the above code, e.g. `paths`.

## Changes

See [the Changelog](CHANGELOG.md) for recent updates

## TODOs

- Sample app, including jQuery usage
- Support RequireJS precompilation via r.js
- Generator and/or template support.. ?

----

Copyright 2011 John Whitley.  See the file MIT-LICENSE for terms.
