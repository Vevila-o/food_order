# 活動設定：日期、KKTIX 活動代碼、手動修正報名人數（M3 的 KKTIX Webhook 上線前的過渡做法）。
class EventsController < ApplicationController
  before_action :set_event, only: %i[edit update]

  def new
    @form = EventForm.new
  end

  def create
    @form = EventForm.new(Event.new, event_params)

    if @form.save
      redirect_to root_path, **saved_flash("已新增活動")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @form = EventForm.new(@event)
  end

  def update
    @form = EventForm.new(@event, event_params)

    if @form.save
      redirect_to root_path, **saved_flash("已更新活動"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_event
    @event = Event.find(params.expect(:id))
  end

  def event_params
    params.expect(event: %i[held_on kktix_slug headcount])
  end

  # 日期不是週二不擋，只提醒
  def saved_flash(message)
    if @form.unusual_weekday?
      { alert: "#{message}。注意：#{@form.held_on.strftime('%-m/%-d')} 是#{@form.event.weekday_label}，Ruby Jam 通常在週二" }
    else
      { notice: message }
    end
  end
end
