require 'requirejs/error'

module RequirejsHelper
  def _data_main(name)
    if name
      name += ".js" unless name =~ /\.js$/
      %Q{data-main="#{javascript_path(name)}"}
    else
      ""
    end
  end

  def requirejs_include_tag(name=nil)
    html = ""
    requirejs = Rails.application.config.requirejs

    if controller.requirejs_included
      raise Requirejs::MultipleIncludeError, "Only one requirejs_include_tag allowed per page."
    end

    unless requirejs.run_config.empty?
      run_config = requirejs.run_config
      if Rails.application.config.assets.digest
        modules = requirejs.build_config['modules'].map { |m| m['name'] }

        # Generate default paths from the modules spec
        default_paths = {}
        modules.each { |m| default_paths[m] = m }

        # Update paths in the requirejs configuration with the defaults
        # and convert the path targets to use digestified asset names.
        cfg = (run_config['paths'] ||= {})
        cfg.merge!(default_paths) { |k, user, default| user }
        cfg.each do |k, v|
          cfg[k] = javascript_path(v).sub /\.js$/,''
        end
      end
      html.concat <<-HTML
      <script>var require = #{run_config.to_json};</script>
      HTML
    end

    html.concat <<-HTML
    <script #{_data_main name} src="#{javascript_path 'require.js'}"></script>
    HTML

    controller.requirejs_included = true
    html.html_safe
  end
end
