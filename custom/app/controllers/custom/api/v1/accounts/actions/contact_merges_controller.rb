# Merging moves the mergee's conversations and deletes it, so freelancers may merge only clients they see.
module Custom::Api::V1::Accounts::Actions::ContactMergesController
  private

  def contacts
    super.crm_visible_to(Current.user)
  end
end
