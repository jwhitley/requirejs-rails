require 'requirejs/error'

module RequirejsHelper
  def _requirejs_data(name, &block)
    {}.tap do |data|
      if name
        name += ".js" unless name =~ /\.js$/
        data['main'] = javascript_path(name)
      end

      data.merge!(yield controller) if block_given?
    end.map do |k, v|
      %Q{data-#{k}="#{v}"}
    end.join(" ")
  end

  def _data_main(name)
    if name
      name += ".js" unless name =~ /\.js$/
      %Q{data-main="#{javascript_path(name)}"}
    else
      ""
    end
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
        run_config = requirejs.run_config
        if Rails.application.config.assets.digest
          modules = requirejs.build_config['modules'].map { |m| requirejs.module_name_for m }

          # Generate digestified paths from the modules spec
          paths = {}
          modules.each { |m| paths[m] = javascript_path(m).sub /\.js$/,'' }

          # Override uesr paths, whose mappings are only relevant in dev mode
          # and in the build_config.
          run_config['paths'] = paths
        end
        html.concat <<-HTML
        <script>var require = #{run_config.to_json};</script>
        HTML
      end

      html.concat <<-HTML
      <script #{_requirejs_data(name, &block)} src="#{javascript_path 'require.js'}"></script>
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
    "<script src='#{javascript_path name}'></script>\n".html_safe
  end
end
