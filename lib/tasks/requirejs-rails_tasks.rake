require 'requirejs/rails/builder'
require 'requirejs/rails/config'

require 'fileutils'
require 'pathname'

require 'sprockets'
require 'tempfile'

require 'active_support/ordered_options'

# Prevent Sprockets::Bootstrap from making the environment immutable,
# as we need to manipulate the environment paths before the asset build.
#
# Without this, task requirejs:assets:purge_js throws an exception from 
# Sprockets::Index#expire_index!, which is in response to any mutating
# method call.
#
if Rails.env == "production"
  require 'sprockets/bootstrap'
  module ::Sprockets
    class Bootstrap
      alias_method :orig_run, :run
      def run(*args)
        config = @app.config
        saved_config_assets_digest = config.assets.digest
        begin
          config.assets.digest = false
          orig_run(*args)
        ensure
          config.assets.digest = saved_config_assets_digest
        end
      end
    end
  end
end

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

  task :setup => ["environment"] do
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
    requirejs.manifest = {}
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
    # stage1 must NOT be run in the production environment
    #
    # Depend on test_node first here so we'll fail early and hard if 
    # node isn't available.
    task :stage1 => ["requirejs:test_node",
                     "requirejs:precompile:prepare_source",
                     "requirejs:precompile:generate_rjs_driver",
                     "requirejs:precompile:run_rjs"]
    task :stage2 => ["requirejs:precompile:digestify_and_compress"]
    
    # Copy all assets to tmp/assets
    task :prepare_source => ["requirejs:setup", 
                             "requirejs:clean", 
                             "requirejs:assets:keep_js"] do
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
                      "requirejs:test_node"] do
      requirejs.config.target_dir.mkpath

      `node #{requirejs.config.driver_path}`
      unless $?.success?
        raise RuntimeError, "Asset compilation with node failed."
      end
    end
    
    # Copy each built asset, identified by a named module in the 
    # build config, to its Sprockets digestified name.
    task :digestify_and_compress => ["requirejs:setup"] do
      requirejs.config.build_config['modules'].each do |m|
        asset_name = "#{m['name']}.js"
        built_asset_path = requirejs.config.target_dir + asset_name
        digest_name = asset_name.sub(/\.(\w+)$/) { |ext| "-#{requirejs.builder.digest_for(built_asset_path)}#{ext}" }
        digest_asset_path = requirejs.config.target_dir + digest_name
        requirejs.manifest[asset_name] = digest_name
        FileUtils.cp built_asset_path, digest_asset_path

        # Create the compressed versions
        File.open("#{built_asset_path}.gz",'wb') do |f|
          zgw = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          zgw.write built_asset_path.read
          zgw.close
        end
        FileUtils.cp "#{built_asset_path}.gz", "#{digest_asset_path}.gz"

        requirejs.config.manifest_path.open('wb') do |f|
          YAML.dump(requirejs.manifest,f)
        end
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
    # Purge all ".../javascripts" directories from the asset paths
    task :purge_js => ["requirejs:setup"] do
      new_paths = requirejs.env_paths.dup.delete_if { |p| p =~ /javascripts$/ && p !~ /requirejs-rails/ }
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

task "assets:precompile:primary" => ["requirejs:precompile:stage2", 
                                     "requirejs:assets:purge_js"]
task "assets:precompile:nondigest" => ["requirejs:assets:purge_js"]
task "assets:precompile" => ["requirejs:precompile:stage1"]
