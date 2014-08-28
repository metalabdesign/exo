require "exo/version"
require "compass/sass_extensions/functions/files/retina_images"

module Exo
  if defined? ::Rails::Engine
    class Engine < ::Rails::Engine; end;
  elsif defined? ::Sprockets
    root_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))
    ::Sprockets.append_path File.join(root_dir, "vendor", "assets", "javascripts")
    ::Sprockets.append_path File.join(root_dir, "app", "assets", "javascripts")
    ::Sprockets.append_path File.join(root_dir, "app", "assets", "stylesheets")
  end
end
