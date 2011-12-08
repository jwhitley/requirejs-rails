module RequirejsHelper
  mattr_accessor :requirejs_included

  def requirejs_include_tag(tag=nil)
    html = ""
    unless requirejs_included
      html = <<-HTML
      <script>
        var require = #{Rails.application.config.requirejs.run_config_json};
      </script>
      #{javascript_include_tag "require"}
      HTML
      requirejs_included = true
    end
    if tag
      html << javascript_include_tag(tag)
    end
    html.html_safe
  end
end