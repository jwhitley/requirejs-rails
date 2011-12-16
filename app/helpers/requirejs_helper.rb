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
    
    if controller.requirejs_included
      raise Requirejs::MultipleIncludeError, "Only one requirejs_include_tag allowed per page."
    end
    html = <<-HTML
    <script>
      var require = #{Rails.application.config.requirejs.run_config_json};
    </script>
    <script #{_data_main name} src="#{javascript_path 'require.js'}"></script>
    HTML
    controller.requirejs_included = true
    html.html_safe
  end
end
