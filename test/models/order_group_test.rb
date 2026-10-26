require "test_helper"

class OrderGroupTest < ActiveSupport::TestCase
  setup do
    @event = create(:event)
    @group = create(:order_group, event: @event)
  end

  test "同組的另一張詢問單是 partner；沒有組或組內只有自己時是 nil" do
    a = create(:order_inquiry, event: @event, order_group: @group)
    b = create(:order_inquiry, event: @event, order_group: @group)
    alone = create(:order_inquiry, event: @event)

    assert_equal b, a.partner
    assert_equal a, b.partner
    assert_nil alone.partner

    b.update!(order_group: nil)
    assert_nil a.reload.partner
  end

  test "詢問單必須和組是同一場活動" do
    other_event = create(:event, held_on: Date.new(2026, 11, 24))
    inquiry = build(:order_inquiry, event: other_event, order_group: @group)

    assert_not inquiry.valid?
    assert inquiry.errors.key?(:order_group)
  end

  test "一組最多兩家" do
    create_list(:order_inquiry, 2, event: @event, order_group: @group)
    @group.reload
    @group.order_inquiries.build(event: @event, merchant: create(:merchant), headcount_at_creation: 1, subtotal: 1)

    assert_not @group.valid?
    assert_includes @group.errors.full_messages, "一組最多 2 家"
  end

  test "刪組只是讓詢問單離組，詢問單保留" do
    inquiry = create(:order_inquiry, event: @event, order_group: @group)

    @group.destroy!

    assert_nil inquiry.reload.order_group_id
  end

  test "刪活動連同組一起刪" do
    create(:order_inquiry, event: @event, order_group: @group)

    assert_difference "OrderGroup.count", -1 do
      @event.destroy!
    end
  end
end
