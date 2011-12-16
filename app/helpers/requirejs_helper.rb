require 'requirejs/error'

module RequirejsHelper
  def requirejs_include_tag(tag=nil)
    html = ""
    
    if controller.requirejs_included
      raise Requirejs::MultipleIncludeError, "Only one requirejs_include_tag allowed per page."
    end
    html = <<-HTML
    <script>
      var require = #{Rails.application.config.requirejs.run_config_json};
    </script>
    #{javascript_include_tag "require"}
    HTML
    controller.requirejs_included = true

    if tag
      html << javascript_include_tag(tag)
    end
    html.html_safe
  end
end
