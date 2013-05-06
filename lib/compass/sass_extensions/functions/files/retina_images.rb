module Compass::SassExtensions::Functions::Files
  def file_exists(image_file)
    Sass::Script::Bool.new !Rails.application.assets.find_asset(image_file.value).nil?
  end

  def retina_filename(image_file)
    filename = image_file.value
    basename, extname = File.basename(filename, ".*"), File.extname(filename)
    Sass::Script::String.new(basename << "@2x" << extname)
  end
end

module Sass::Script::Functions
  include Compass::SassExtensions::Functions::Files
end
