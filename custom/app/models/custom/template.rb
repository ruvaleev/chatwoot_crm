# A personal reply template; team-wide ones are Chatwoot canned responses.
class Custom::Template < ApplicationRecord
  self.table_name = 'crm_templates'

  belongs_to :user

  validates :short_code, presence: true, length: { maximum: 50 }
  validates :content, presence: true
end
