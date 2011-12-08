require 'requirejs/rails/builder'
require 'requirejs/rails/config'

require 'fileutils'
require 'pathname'
require 'tempfile'

require 'active_support/ordered_options'

namespace :requirejs do
  
  # From Rails 3 assets.rake; we have the same problem:
  #
  # We are currently running with no explicit bundler group
  # and/or no explicit environment - we have to reinvoke rake to
  # execute this task.
  def invoke_or_reboot_rake_task(task)
    if ENV['RAILS_GROUPS'].to_s.empty? || ENV['RAILS_ENV'].to_s.empty?
      ruby_rake_task task
    else
      Rake::Task[task].invoke
    end
  end
  
  class String
    def unindent
      gsub /^#{self[/\A\s*/]}/, ''
    end
  end
  
  requirejs = ActiveSupport::OrderedOptions.new
  
  task :clean => ["requirejs:setup"] do
    FileUtils.remove_entry_secure(requirejs.config.source_dir, true)
    FileUtils.remove_entry_secure(requirejs.driver_path, true)
  end
  
  task :setup => :environment do
    unless Rails.application.config.assets.enabled
      warn "Cannot precompile assets if sprockets is disabled. Please set config.assets.enabled to true"
      exit
    end

    # Ensure that action view is loaded and the appropriate
    # sprockets hooks get executed
    _ = ActionView::Base

    requirejs.env = Rails.application.assets
    # Preserve the original asset paths, as we'll be manipulating them later
    requirejs.env_paths = requirejs.env.paths.dup
    requirejs.config = Rails.application.config.requirejs
    requirejs.builder = Requirejs::Rails::Builder.new(requirejs.config)
    requirejs.orig_compressor = Rails.application.assets.js_compressor
  end
  
  task :test_node do
    begin
      `node -v`
    rescue Errno::ENOENT
      STDERR.puts <<-EOM
Unable to find 'node' on the current path, required for precompilation
using the requirejs-ruby gem. To install node.js, see http://nodejs.org/
OS X Homebrew users can use 'brew install node'.
EOM
      exit 1
    end
  end
  
  namespace :precompile do
    # Depend on test_node first here so we'll fail early and hard if 
    # node isn't available.
    task :all => ["requirejs:test_node",
                  "requirejs:precompile:prepare_source",
                  "requirejs:precompile:generate_rjs_driver",
                  "requirejs:precompile:run_rjs",
                  "requirejs:precompile:digestify"]
    
    # Copy all assets to tmp/assets
    task :prepare_source => ["requirejs:setup", 
                             "requirejs:clean", 
                             "requirejs:assets:keep_js",
                             "requirejs:assets:disable_compressor"] do
      requirejs.config.source_dir.mkpath
      requirejs.env.each_logical_path do |logical_path|
        if asset = requirejs.env.find_asset(logical_path)
          filename = requirejs.config.source_dir + asset.logical_path
          filename.dirname.mkpath
          
          asset.write_to(filename)
        end
      end
    end
    
    task :generate_rjs_driver => ["requirejs:setup"] do
      requirejs.builder.generate_rjs_driver
    end

    task :run_rjs => ["requirejs:setup", 
                      "requirejs:test_node", 
                      "requirejs:assets:disable_compressor"] do
      requirejs.config.target_dir.mkpath

      `node #{requirejs.config.driver_path}`
      unless $?.success?
        raise RuntimeError, "Asset compilation with node failed."
      end
    end
    
    # Copy each built asset, identified by a named module in the 
    # build config, to its Sprockets digestified name.
    task :digestify do
      requirejs.config.build_config['modules'].each do |m|
        asset = requirejs.env.find_asset(m['name'])
        built_asset_name = requirejs.config.target_dir + asset.logical_path
        digest_asset_name = requirejs.config.target_dir + asset.digest_path
        FileUtils.cp built_asset_name, digest_asset_name
      end      
    end
  end

  desc "Precompile RequireJS-managed assets"
  task :precompile do
    invoke_or_reboot_rake_task "requirejs:precompile:all"
  end
  
  # We remove all .js assets from the Rails Asset Pipeline when 
  # precompiling, as those are handled by r.js. Conversely, r.js 
  # only sees .js assets. For now, this is by path convention; any
  # asset path ending in "javascript". If you've got javascripts in 
  # your stylesheets directory, then heaven help you. You've got bigger
  # problems.
  namespace :assets do
    task :disable_compressor do
      # Save then disable asset compression
      Rails.application.assets.js_compressor = nil
    end

    task :enable_compressor do
      Rails.application.assets.js_compressor = requirejs.orig_compressor
    end

    # Purge all ".../javascripts" directories from the asset paths
    task :purge_js => ["requirejs:setup"] do
      new_paths = requirejs.env_paths.dup.delete_if { |p| p =~ /javascripts$/ }
      requirejs.env.clear_paths
      new_paths.each { |p| requirejs.env.append_path(p) }
    end
    
    # Preserve only ".../javascripts" directories
    task :keep_js => ["requirejs:setup"] do
      new_paths = requirejs.env_paths.dup.keep_if { |p| p =~ /javascripts$/ }
      requirejs.env.clear_paths
      new_paths.each { |p| requirejs.env.append_path(p) }
    end
  end
end

task "assets:precompile:primary" => ["requirejs:assets:purge_js", 
                                     "requirejs:assets:enable_compressor"]
task "assets:precompile:nondigest" => ["requirejs:assets:purge_js", 
                                       "requirejs:assets:enable_compressor"]
task "assets:precompile:all" => ["requirejs:precompile:all"]
