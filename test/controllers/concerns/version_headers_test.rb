require "test_helper"

class VersionHeadersTest < ActionDispatch::IntegrationTest
  test "responses carry the configured version and revision" do
    Rails.application.config.stubs(:app_version).returns("1.2.3")
    Rails.application.config.stubs(:git_revision).returns("abc1234")

    sign_in :david
    get room_url(rooms(:hq))

    assert_response :success
    assert_equal "1.2.3", response.headers["X-Version"]
    assert_equal "abc1234", response.headers["X-Rev"]
  end

  test "version headers are set on anonymous responses too" do
    Rails.application.config.stubs(:app_version).returns("1.2.3")
    Rails.application.config.stubs(:git_revision).returns("abc1234")

    get new_session_url

    assert_response :success
    assert_equal "1.2.3", response.headers["X-Version"]
    assert_equal "abc1234", response.headers["X-Rev"]
  end
end
