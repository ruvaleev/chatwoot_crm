# A one-time sign-in link for a freelancer (crm/design/brief.md, "Вход"): opened once within a day, it lets them set
# a password. Only the token digest is stored; the link itself is shown to the manager once.
class Custom::Invitation < ApplicationRecord
  self.table_name = 'crm_invitations'

  LIFETIME = 24.hours

  belongs_to :user

  scope :usable, -> { where(used_at: nil).where(expires_at: Time.current..) }

  # A new link replaces any unused one.
  def self.issue!(user)
    token = SecureRandom.urlsafe_base64(32)
    transaction do
      user.crm_invitations.where(used_at: nil).delete_all
      create!(user: user, token_digest: digest(token), expires_at: LIFETIME.from_now)
    end
    token
  end

  def self.find_usable(token)
    usable.find_by(token_digest: digest(token))
  end

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token)
  end

  def accept!(password, confirmation)
    transaction do
      user.update!(password: password, password_confirmation: confirmation)
      update!(used_at: Time.current)
    end
  end
end
