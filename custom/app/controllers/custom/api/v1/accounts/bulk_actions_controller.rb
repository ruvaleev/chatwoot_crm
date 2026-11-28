# Contact bulk actions look contacts up across the account, so a freelancer's ids are narrowed to contacts they see.
module Custom::Api::V1::Accounts::BulkActionsController
  private

  def contact_params
    return super unless Current.user.crm_freelancer?

    super.merge(ids: Current.account.contacts.where(id: params[:ids]).crm_visible_to(Current.user).ids)
  end
end
