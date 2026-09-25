require "test_helper"

WebMock.disable!

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Reduced motion collapses CSS animations (see _reset.css), so Capybara never clicks an
  # element that is still moving, e.g. the boost form while it scales in.
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument "--force-prefers-reduced-motion"
  end

  include SystemTestHelper
end
