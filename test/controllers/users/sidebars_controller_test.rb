require "test_helper"

class Users::SidebarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "show" do
    get user_sidebar_url

    users(:david).rooms.opens.each do |room|
      assert_match /#{room.name}/, @response.body
    end
  end

  test "unread directs" do
    rooms(:david_and_jason).messages.create! client_message_id: 999, body: "Hello", creator: users(:jason)

    get user_sidebar_url

    assert_select "#direct_rooms .unread", count: 1
    assert_select "#" + dom_id(rooms(:david_and_jason), :list) + ".unread"
  end

  test "unread other" do
    rooms(:watercooler).messages.create! client_message_id: 999, body: "Hello", creator: users(:jason)

    get user_sidebar_url

    assert_select "#shared_rooms .unread", count: 1
    assert_select "#" + dom_id(rooms(:watercooler), :list) + ".unread"
  end
end
