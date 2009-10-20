$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'slender_t'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  def simple_content
    File.read(simple_filename)
  end

  def simple_filename
    File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'simple.csv'))
  end
end
