require "test_helper"

class PwaControllerTest < ActionDispatch::IntegrationTest
  # Both actions are allow_unauthenticated_access: the browser fetches them
  # before anyone has signed in, so they have to stay reachable anonymously.
  test "manifest is served to anonymous visitors" do
    get webmanifest_url(format: :json)

    assert_response :success
    assert_includes response.content_type, "application/json"
    assert response.parsed_body["name"].present?
  end

  test "service worker is served to anonymous visitors" do
    get service_worker_url(format: :js)

    assert_response :success
    assert_includes response.content_type, "javascript"
    assert_includes response.body, 'self.addEventListener("push",'
  end
end
