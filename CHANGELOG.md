# v0.5.4

- Upgrade to RequireJS and r.js 1.0.5
- Pull request #31, closes #30.  Thanks @karelim!

# v0.5.3

- Upgrade to RequireJS and r.js 1.0.4
- Pulled #22, fix for asset compliation failure with no config/requirejs.yml.
  Thanks @arehberg!

# v0.5.2

- Upgrade to RequireJS and r.js 1.0.3

# v0.5.1

- This is a quick turn to fix an issue that could trigger an Anonymous mismatched define() error from require.js and/or r.js.

    The preferred way to use the helper tag is now with an argument, like
    so:

    ```erb
    <%= requirejs_include_tag "application" %>
    ```

    This usage ensures that the above helper will correctly generate a
    data-main attribute for the script tag.  The requirejs_include_tag
    helper still works without an argument, and won't generate data-main
    in that case.

    Thanks to Andrew de Andrade for the catch.

# v0.5.0

- Precompilation via `rake assets:precompile` is now implemented.
- gem configuration via application.js is deprecated.
- Application-specific require.js configuration lives in `config/requirejs.yml`.
- See [README](README.md) for updated usage details.

# v0.0.2

- Fixed stupid problems with Rails::Engine instantiation.
- Test improvements
- Upgrade to RequireJS 1.0.2

# v0.0.1

- Birthday!
- This gem makes `require.js` and the `order.js` plugin available to the Rails 3 Asset Pipeline.

