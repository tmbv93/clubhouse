module Admin
  class MeetingsController < AdminController
    before_action :set_meeting, only: %i[show edit update destroy]

    def new
      @meeting = Meeting.new
    end

    def create
      @meeting = Current.platform.meetings.new(meeting_params)

      if @meeting.save
        handle_invites(@meeting)
        @meeting.log!(:created, by: Current.user)
        notice = "#{@meeting.title} saved"
        redirect_to admin_meeting_url(@meeting), notice: notice
      else
        render_inside_modal :new, status: :unprocessable_content
      end
    end

    def index
      set_data_table_page by_table_tab(Current.platform.meetings),
                          allow_sort_by: %w[meetings.title meetings.happens_at]
    end

    def show
    end

    def edit
    end

    def update
      if @meeting.update(meeting_params)
        render "admin/meetings/show"
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @meeting.destroy!
      redirect_to admin_meetings_path, notice: "Meeting deleted"
    end

    private

    def set_meeting
      @meeting = Current.platform.meetings.find(params[:id])
    end

    def meeting_params
      params.require(:meeting).permit(:title, :happens_at, :location, :description, :open)
    end

    def by_table_tab(meetings)
      case params[:tab]
      when "past"
        meetings.past.order(happens_at: :desc)
      else
        meetings.planned.order(
          Meeting.arel_table[:happens_at].asc.nulls_first,
          Meeting.arel_table[:created_at].desc
        )
      end
    end

    def handle_invites(meeting)
      group_ids = params[:invite_group_ids]&.split(",")&.compact
      return unless group_ids&.any?

      if group_ids.include?("everyone")
        invite_groups = [Current.platform]
      else
        invite_groups = Current.platform.groups.where(id: group_ids)
      end

      Meetings::MassInviteJob.perform_now(meeting, invite_groups: invite_groups)
    end
  end
end
