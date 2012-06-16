require 'requirejs/error'

module RequirejsHelper
  # EXPERIMENTAL: Additional priority settings appended to
  # any user-specified priority setting by requirejs_include_tag.
  # Used for JS test suite integration.
  mattr_accessor :_priority
  @@_priority = []

  def _requirejs_data(name, &block)
    {}.tap do |data|
      if name
        name += ".js" unless name =~ /\.js$/
        data['main'] = _javascript_path(name).sub(/\.js$/,'')
      end

      data.merge!(yield controller) if block_given?
    end.map do |k, v|
      %Q{data-#{k}="#{v}"}
    end.join(" ")
  end

  def requirejs_include_tag(name=nil, &block)
    requirejs = Rails.application.config.requirejs

    if requirejs.loader == :almond
      name = requirejs.module_name_for(requirejs.build_config['modules'][0])
      return _almond_include_tag(name, &block)
    end

    html = ""

    _once_guard do
      unless requirejs.run_config.empty?
        run_config = requirejs.run_config.dup
        unless _priority.empty?
          run_config = run_config.dup
          run_config[:priority] ||= []
          run_config[:priority].concat _priority
        end
        if Rails.application.config.assets.digest
          modules = requirejs.build_config['modules'].map { |m| requirejs.module_name_for m }

          # Generate digestified paths from the modules spec
          paths = {}
          modules.each { |m| paths[m] = _javascript_path(m).sub /\.js$/,'' }

          if run_config.has_key? 'paths'
            # Add paths for assets specified by full URL (on a CDN)
            run_config['paths'].each { |k,v| paths[k] = v if v =~ /^https?:/ }
          end

          # Override user paths, whose mappings are only relevant in dev mode
          # and in the build_config.
          run_config['paths'] = paths
        end
        html.concat <<-HTML
        <script>var require = #{run_config.to_json};</script>
        HTML
      end

      html.concat <<-HTML
      <script #{_requirejs_data(name, &block)} src="#{_javascript_path 'require.js'}"></script>
      HTML

      html.html_safe
    end
  end

  def _once_guard
    if defined?(controller) && controller.requirejs_included
      raise Requirejs::MultipleIncludeError, "Only one requirejs_include_tag allowed per page."
    end

    retval = yield

    controller.requirejs_included = true if defined?(controller)
    retval
  end

  def _almond_include_tag(name, &block)
    "<script src='#{_javascript_path name}'></script>\n".html_safe
  end

  def _javascript_path(name)
    if defined?(javascript_path)
      javascript_path(name)
    else
      "/assets/#{name}"
    end
  end
end
