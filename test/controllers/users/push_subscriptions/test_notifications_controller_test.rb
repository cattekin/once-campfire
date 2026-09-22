require "test_helper"

class Users::PushSubscriptions::TestNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    stub_web_push_dns_resolution
  end

  test "create delivers a notification to the subscription" do
    WebPush.expects(:payload_send).with(has_entry(endpoint: push_subscriptions(:david_chrome).endpoint)).once

    post user_push_subscription_test_notifications_url(push_subscriptions(:david_chrome))

    assert_redirected_to user_push_subscriptions_url
  end

  test "create cannot reach another user's subscription" do
    WebPush.expects(:payload_send).never

    assert_raises ActiveRecord::RecordNotFound do
      post user_push_subscription_test_notifications_url(push_subscriptions(:jason_chrome))
    end
  end
end
