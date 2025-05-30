module Admin
  class MeetingsController < AdminController
    include ImageUploadHandling

    before_action :set_meeting, only: %i[show edit update destroy]
    before_action lambda {
      resize_image_file(meeting_params[:logo], width: 300, height: 300)
    }, only: [ :update ]

    def new
      date = params.fetch(:start_date, Date.today).to_date
      @meeting = Meeting.new(starts_at: date)
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
      set_data_table_page @meeting.invites.includes(:rsvp, membership: :user),
                          default_sort_by: "rsvps.confirmation_sent_at, invites.created_at",
                          default_sort_direction: :desc
    end

    def edit
    end

    def update
      if @meeting.update(meeting_params)
        set_data_table_page @meeting.invites.includes(:rsvp, :messages, membership: :user),
                            default_sort_by: "users.first_name",
                            default_sort_direction: :asc
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
      params.require(:meeting).permit(:title, :starts_at, :location, :description, :open, :logo)
    end

    def by_table_tab(meetings)
      case params[:tab]
      when "past"
        meetings.past.order(starts_at: :desc)
      else
        meetings.planned.order(
          Meeting.arel_table[:starts_at].asc.nulls_first,
          Meeting.arel_table[:created_at].desc
        )
      end
    end

    def handle_invites(meeting)
      group_ids = params[:invite_group_ids]&.split(",")&.compact
      return unless group_ids&.any?

      if group_ids.include?("everyone")
        invite_groups = [ Current.platform ]
      else
        invite_groups = Current.platform.groups.where(id: group_ids)
      end

      invite_groups.each do |invite_group|
        Meetings::MassInviteJob.perform_later(meeting, invite_group: invite_group)
      end
    end
  end
end
