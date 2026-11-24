# CRM: one-time sign-in links for freelancers (crm/PRD.md, stage D3). See crm/docs/core-changes.md.
class CreateCrmInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_invitations do |t|
      t.references :user, null: false, index: true
      t.string :token_digest, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps
    end
  end
end
