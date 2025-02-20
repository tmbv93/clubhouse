module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id])
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path
  end

  def after_authentication_url(user)
    session.delete(:return_to_after_authenticating) || default_landing_url(user)
  end

  def default_landing_url(user)
    user.has_admin_rights_at?(Current.platform) ? admin_dashboard_url : member_dashboard_url
  end

  def start_new_session_for(user)
    platform = params[:platform_id].present? ? user.platforms.find(params[:platform_id]) : user.default_platform

    user.sessions.create!(
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
      platform: platform
    ).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end
  end

  def switch_platform_to(platform)
    return false unless platform.users.include?(Current.session.user)

    Current.session.update(platform: platform)
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
