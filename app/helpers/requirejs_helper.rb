require 'requirejs/error'

module RequirejsHelper
  # EXPERIMENTAL: Additional priority settings appended to
  # any user-specified priority setting by requirejs_include_tag.
  # Used for JS test suite integration.
  mattr_accessor :_priority
  @@_priority = []

  def requirejs_include_tag(name=nil, &block)
    if requirejs.loader == :almond
      @asset = requirejs.module_name_for(requirejs.build_config['modules'][0])
      almond_include_tag
    else
      once_guard
      @asset = name
      [generate_config_html, include_tag(&block)].join.html_safe
    end
  end

  private
  def almond_include_tag
    "<script src='#{get_javascript_path @asset}'></script>\n".html_safe
  end

  def include_tag(&block)
    "<script #{requirejs_data(&block)} src='#{get_javascript_path 'require.js'}'></script>\n"
  end

  def requirejs
    @requirejs ||= Rails.application.config.requirejs
  end

  def requirejs_data(&block)
    return unless @asset

    attributes_hash(&block).map do |attribute, value|
      %Q{data-#{attribute}="#{value}"}
    end.join(" ")
  end

  def attributes_hash(&block)
    attributes = {}
    attributes['main'] = strip_js_suffix(get_javascript_path(@asset)).
                    sub(baseUrl, '').
                    sub(/\A\//, '')

    attributes.merge!(yield controller) if block_given?
    attributes
  end

  def once_guard
    return unless defined?(controller)

    if controller.requirejs_included
      raise Requirejs::MultipleIncludeError,
        "Only one requirejs_include_tag allowed per page."
    else
      controller.requirejs_included = true
    end
  end

  def get_javascript_path(asset)
    if defined?(javascript_path)
      javascript_path(asset)
    else
      "/assets/#{add_js_suffix(asset)}"
    end
  end

  def baseUrl
    js_asset_path = get_javascript_path @asset
    uri = URI.parse(js_asset_path)
    asset_host = uri.host && js_asset_path.sub(uri.request_uri, '')
    [asset_host, Rails.application.config.assets.prefix].join
  end

  def generate_config_html
    return if requirejs.run_config.empty?
    "<script>var require = #{run_config};</script>\n"
  end

  def run_config
    run_config = requirejs.run_config.dup

    add_priority_modules! run_config
    add_cdn_paths! run_config
    run_config['baseUrl'] = baseUrl
    run_config.to_json
  end

  def add_cdn_paths!(run_config)
    return unless Rails.application.config.assets.digest
    paths = digestified_paths_from_module_names
    paths.merge! paths_from_run_config(run_config)

    # Override user paths, whose mappings are only relevant in dev mode
    # and in the build_config.
    run_config['paths'] = paths
  end

  def add_priority_modules!(run_config)
    return if _priority.empty?
    run_config[:priority] ||= []
    run_config[:priority].concat _priority
  end

  def digestified_paths_from_module_names
    requirejs.module_names.inject({}) do |paths, module_name|
      paths[module_name] = strip_js_suffix(get_javascript_path(module_name))
      paths
    end
  end

  def paths_from_run_config(run_config)
    return {} unless run_config.has_key? 'paths'
    # Add paths for assets specified by full URL (on a CDN)
    run_config['paths'].select { |k,v| v =~ /^https?:/ }
  end

  def add_js_suffix(asset)
    asset + ".js" unless asset =~ /\.js$/
  end

  def strip_js_suffix(asset)
    asset.sub(/\.js$/, '')
  end
end
