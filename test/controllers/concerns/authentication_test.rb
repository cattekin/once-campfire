require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "anonymous requests are redirected to sign in" do
    get room_url(rooms(:hq))

    assert_redirected_to new_session_url
  end

  test "signing in returns to the page that required authentication" do
    get room_url(rooms(:hq))
    assert_redirected_to new_session_url

    post session_url, params: { email_address: "david@37signals.com", password: "secret123456" }

    assert_redirected_to room_url(rooms(:hq))
  end

  test "bot keys do not grant access to regular pages" do
    get room_url(rooms(:watercooler), bot_key: users(:bender).bot_key)

    assert_response :forbidden
  end
end
