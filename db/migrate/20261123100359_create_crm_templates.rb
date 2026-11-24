# CRM: personal reply templates of each user (crm/PRD.md, stage D3). See crm/docs/core-changes.md.
class CreateCrmTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_templates do |t|
      t.references :user, null: false, index: true
      t.string :short_code, null: false
      t.text :content, null: false
      t.timestamps
    end
  end
end
