class Management::UsersController < Management::BaseController

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.email.blank?
      user_without_email
    else
      user_with_email
    end

    @user.terms_of_service = '1'
    verificado = verificar_residencia
    @user.residence_verified_at = verificado
    @user.verified_at = verificado

    if @user.save then
      render :show
    else
      render :new
    end
  end

  def erase
    managed_user.erase(t("management.users.erased_by_manager", manager: current_manager['login'])) if current_manager.present?
    destroy_session
    redirect_to management_document_verifications_path, notice: t("management.users.erased_notice")
  end

  def logout
    destroy_session
    redirect_to management_root_url, notice: t("management.sessions.signed_out_managed_user")
  end

  private

    def user_params
      params.require(:user).permit(:document_type, :document_number, :username, :email, :date_of_birth)
    end

    def destroy_session
      session[:document_type] = nil
      session[:document_number] = nil
    end

    def user_without_email
      new_password = "aAbcdeEfghiJkmnpqrstuUvwxyz23456789$!".split('').sample(10).join('')
      @user.password = new_password
      @user.password_confirmation = new_password

      @user.email = nil
      @user.confirmed_at = Time.current

      @user.newsletter = false
      @user.email_on_proposal_notification = false
      @user.email_digest = false
      @user.email_on_direct_message = false
      @user.email_on_comment = false
      @user.email_on_comment_reply = false
    end

    def user_with_email
      @user.skip_password_validation = true
    end

end
