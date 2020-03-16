class Invocation < ApplicationRecord
  belongs_to :campaign

  scope :llg_invocations_of, ->(linked_in_account){
    joins(:campaign).
      where("campaigns.linked_in_account_id = ?", linked_in_account.id).
      where("campaigns.script_type = ?", "LLG")
  }
end
