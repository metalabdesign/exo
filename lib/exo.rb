require "exo/version"

module Exo
  if defined? ::Rails::Engine
    class Rails::Engine < ::Rails::Engine; end;
  elsif defined? ::Sprockets
    root_dir = File.expand_path(File.dirname(File.dirname(__FILE__)))
    ::Sprockets.append_path File.join(root_dir, "vendor", "assets", "javascripts")
    ::Sprockets.append_path File.join(root_dir, "app", "assets", "javascripts")
    ::Sprockets.append_path File.join(root_dir, "app", "assets", "stylesheets")
  end
end
