require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "socket lifecycle callbacks remain public with Sentry instrumentation" do
    assert ApplicationCable::Connection.public_method_defined?(:handle_open)
    assert ApplicationCable::Connection.public_method_defined?(:handle_close)
  end

  test "connects with valid user_id cookie" do
    cookies.signed[:session_token] = sessions(:david_safari).token

    connect

    assert_equal users(:david), connection.current_user
  end

  test "rejects connection with missing user_id cookie" do
    assert_reject_connection { connect }
  end

  test "rejects connection with invalid user_id cookie" do
    cookies.signed[:session_token] = -1

    assert_reject_connection { connect }
  end
end
