module Admin
  class MembershipsController < AdminController
    before_action :set_membership, only: [ :show, :edit, :update, :destroy ]

    def new
      @membership = Membership.new
      @membership.build_user
    end

    def create
      @membership = Current.platform.memberships.new(membership_params)
      @membership.user = find_or_invite_user(@membership.user)

      if @membership.save
        redirect_to admin_memberships_path(created: @membership.id), notice: "Added #{@membership.user.first_name}"
      else
        render_inside_modal :new, status: :unprocessable_content
      end
    end

    def index
      set_data_table_page by_table_tab(Current.platform.memberships.joins(:user)),
                          allow_sort_by: %w[users.first_name users.last_name users.email],
                          default_sort_direction: :desc
    end

    def show
    end

    def edit
    end

    def update
      if @membership.update(membership_params.merge(membership_role_params))
        redirect_to admin_membership_path(@membership), notice: "Member saved."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @membership.user == Current.user
        return redirect_to admin_membership_path(@membership), notice: "You can't delete yourself!"
      end

      @membership.destroy!
      redirect_to admin_memberships_path, notice: "Deleted #{@membership.user.full_name}"
    end

    private

    def set_membership
      @membership = Current.platform.memberships.find(params[:id])
    end

    def membership_params
      params.require(:membership).permit(user_attributes: [ :id, :email, :first_name, :last_name ])
    end

    # brakeman:ignore PermitAttributes
    def membership_role_params
      # Brakeman: These two guard clauses should ensure these code lines are safe
      return {} unless Current.user.has_super_admin_rights_at?(Current.platform)
      return {} if Current.user == @membership.user

      params.require(:membership).permit(:role)
    end

    def find_or_invite_user(user)
      existing_user = User.find_by(email: user.email)
      return existing_user if existing_user

      # User must reset their password when invited
      temporary_password = SecureRandom.base58
      user.password = temporary_password
      user
    end

    def by_table_tab(memberships)
      return memberships unless params[:tab].present?

      @group = Current.platform.groups.find(params[:tab])
      @group.memberships
    end
  end
end
