require 'fileutils'
require 'pathname'
require 'tempfile'

require 'active_support/ordered_options'

namespace :requirejs do
  
  class String
    def unindent
      gsub /^#{self[/\A\s*/]}/, ''
    end
  end
  
  def env
    Rails.application.assets
  end
  
  def config
    Rails.application.config
  end

  requirejs = ActiveSupport::OrderedOptions.new
  
  task :clean => ["requirejs:setup"] do
    FileUtils.remove_entry_secure(requirejs.source_dir, true)
    FileUtils.remove_entry_secure(requirejs.rjs_config_file, true)
  end
  
  task :setup => :environment do
    # Preserve the original asset paths, as we'll be manipulating them later
    requirejs.env_paths = env.paths.dup
    requirejs.tmp_dir = Rails.root + 'tmp'
    requirejs.source_dir = requirejs.tmp_dir + 'assets'
    requirejs.target_dir = Rails.root + 'public/assets'
    requirejs.bin_dir = Pathname.new(__FILE__+'/../../../bin').cleanpath
    requirejs.rjs_path = requirejs.bin_dir+'r.js'
    
    # This is the config generated for r.js' use
    requirejs.rjs_config_file = requirejs.tmp_dir+'app.build.js'

    # Our r.js config defaults
    requirejs.build_config = <<-EOF.unindent.strip
    { 
      baseUrl: "#{requirejs.source_dir}",
      dir: "#{requirejs.target_dir}",
      modules: [ { name: 'application' } ],
      fileExclusionRegExp: /.?/
    }
    EOF

    # The user-supplied config parameters, to be merged with the default params.
    # This file must contain a single JavaScript object.
    requirejs.user_config_file = Pathname.new(Rails.application.paths.config.first)+'rjs.build.js'
    if requirejs.user_config_file.exist?
      requirejs.user_config = requirejs.user_config_file.read
    end

    if requirejs.user_config
      merge_json = <<-EOF.unindent
      var o = #{requirejs.build_config};
      var u = #{requirejs.user_config};
      for (var i in u) { 
        o[i] = u[i];
      }
      console.log(o);
      EOF

      begin
        f = Tempfile.new('rjs.merge',requirejs.tmp_dir)
        f.write(merge_json)
        f.close
        requirejs.build_config = `node #{f.path}`
      ensure
        f.close!
      end
    end
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
                  "requirejs:precompile:generate_rjs_config",
                  "requirejs:precompile:run_rjs"]
    
    # Copy all assets to tmp/assets
    task :prepare_source => ["requirejs:setup", "requirejs:clean", "requirejs:assets:keep_js"] do
      requirejs.source_dir.mkpath
      env.each_logical_path do |logical_path|
        if asset = env.find_asset(logical_path)
          filename = requirejs.source_dir + asset.logical_path
          filename.dirname.mkpath
          asset.write_to(filename)
        end
      end      
    end
    
    task :generate_rjs_config => ["requirejs:setup"] do
      (requirejs.rjs_config_file).open('w') do |f|
        f.write(requirejs.build_config)
      end
    end

    task :run_rjs => ["requirejs:setup", "requirejs:test_node"] do
      requirejs.target_dir.mkpath
      `node #{requirejs.rjs_path} -o #{requirejs.rjs_config_file}`
    end
  end
  
  desc "Precompile RequireJS-managed assets"
  task :precompile => ["requirejs:precompile:all"]
  
  # We remove all .js assets from the Rails Asset Pipeline when 
  # precompiling, as those are handled by r.js. Conversely, r.js 
  # only sees .js assets. For now, this is by path convention; any
  # asset path ending in "javascript". If you've got javascripts in 
  # your stylesheets directory, then heaven help you. You've got bigger
  # problems.
  namespace :assets do
    # Purge all ".../javascripts" directories from the asset paths
    task :purge_js => ["requirejs:setup"] do
      new_paths = requirejs.env_paths.dup.delete_if { |p| p =~ /javascripts$/ }
      env.clear_paths
      new_paths.each { |p| env.append_path(p) }
    end
    
    # Preserve only ".../javascripts" directories
    task :keep_js => ["requirejs:setup"] do
      new_paths = requirejs.env_paths.dup.keep_if { |p| p =~ /javascripts$/ }
      env.clear_paths
      new_paths.each { |p| env.append_path(p) }
    end
  end
end

task "assets:precompile:primary" => ["requirejs:assets:purge_js"]
task "assets:precompile:nondigest" => ["requirejs:assets:purge_js"]
