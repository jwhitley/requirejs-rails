require "requirejs/error"
require "requirejs/rails/view"

module RequirejsHelper
  def self.included(clazz)
    clazz.class_eval do
      extend Forwardable

      # Delegate all JavaScript path queries to the specially modified internal view.
      def_delegators :view, :javascript_path
    end
  end

  # EXPERIMENTAL: Additional priority settings appended to
  # any user-specified priority setting by requirejs_include_tag.
  # Used for JS test suite integration.
  mattr_accessor :_priority
  @@_priority = []

  def requirejs_include_tag(name = nil, &block)
    requirejs = Rails.application.config.requirejs

    if requirejs.loader == :almond
      name = requirejs.module_name_for(requirejs.build_config['modules'][0])
      return almond_include_tag(name, &block)
    end

    html = ""

    once_guard do
      rjs_attributes = {
          src: path_to_javascript("require")
      }

      rjs_attributes = rjs_attributes.merge(Hash[block.call(controller).map do |key, value|
        ["data-#{key}", value]
      end]) \
        if block

      html.concat(content_tag(:script, "", rjs_attributes))

      unless requirejs.run_config.empty?
        run_config = requirejs.run_config.dup

        unless _priority.empty?
          run_config = run_config.dup
          run_config[:priority] ||= []
          run_config[:priority].concat _priority
        end

        if Rails.application.config.assets.digest
          assets_precompiled = !Rails.application.config.assets.compile
          modules = requirejs.build_config["modules"].map {|m| requirejs.module_name_for m}
          user_paths = requirejs.build_config["paths"] || {}

          # Generate digestified paths from the modules spec
          paths = {}

          modules.each do |module_name|
            script_path = if !assets_precompiled
              # If modules haven't been precompiled, search for them based on their user-defined paths before using the
              # module name.
              user_paths[module_name] || module_name
            else
              # If modules have been precompiled, the script path is just the module name.
              module_name
            end

            paths[module_name] = path_to_javascript(script_path).gsub(/\.js$/, "")
          end

          if run_config.has_key? "paths"
            # Add paths for assets specified by full URL (on a CDN)
            run_config["paths"].each do |k, v|
              paths[k] = v if v.is_a?(Array) || v =~ /^(https?:)?\/\//
            end
          end

          # Override user paths, whose mappings are only relevant in dev mode
          # and in the build_config.
          run_config["paths"] = paths
        end

        run_config["baseUrl"] = base_url(name)

        html.concat(content_tag(:script) do
          script = "require.config(#{run_config.to_json});"

          # Pass an array to `require`, since it's a top-level module about to be loaded asynchronously (see
          # `http://requirejs.org/docs/errors.html#notloaded`).
          script.concat(" require([#{name.dump}]);") \
            if name

          script.html_safe
        end)
      end

      html.html_safe
    end
  end

  private

  def once_guard
    if defined?(controller) && controller.requirejs_included
      raise Requirejs::MultipleIncludeError, "Only one requirejs_include_tag allowed per page."
    end

    retval = yield

    controller.requirejs_included = true if defined?(controller)
    retval
  end

  def almond_include_tag(name, &block)
    content_tag(:script, "", src: javascript_path(name))
  end

  def base_url(js_asset)
    js_asset_path = javascript_path(js_asset)
    uri = URI.parse(js_asset_path)
    asset_host = uri.host && js_asset_path.sub(uri.request_uri, '')
    [asset_host, Rails.application.config.relative_url_root, Rails.application.config.assets.prefix].join
  end

  def view
    @view ||= Requirejs::Rails::View.new
  end
end
