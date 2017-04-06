require 'test_helper'

class TrackingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tracking = trackings(:one)
  end

  test "should get index" do
    get trackings_url
    assert_response :success
  end

  test "should get new" do
    get new_tracking_url
    assert_response :success
  end

  test "should create tracking" do
    assert_difference('Tracking.count') do
      post trackings_url, params: { tracking: { carrier: @tracking.carrier, code: @tracking.code, delivery_status: @tracking.delivery_status, notification_url: @tracking.notification_url, url: @tracking.url } }
    end

    assert_redirected_to tracking_url(Tracking.last)
  end

  test "should show tracking" do
    get tracking_url(@tracking)
    assert_response :success
  end

  test "should get edit" do
    get edit_tracking_url(@tracking)
    assert_response :success
  end

  test "should update tracking" do
    patch tracking_url(@tracking), params: { tracking: { carrier: @tracking.carrier, code: @tracking.code, delivery_status: @tracking.delivery_status, notification_url: @tracking.notification_url, url: @tracking.url } }
    assert_redirected_to tracking_url(@tracking)
  end

  test "should destroy tracking" do
    assert_difference('Tracking.count', -1) do
      delete tracking_url(@tracking)
    end

    assert_redirected_to trackings_url
  end
end
