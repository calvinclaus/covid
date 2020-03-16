class ProspectPool < ApplicationRecord
  has_many :prospect_pool_campaign_associations, dependent: :delete_all
  has_many :campaigns, through: :prospect_pool_campaign_associations
  has_many :prospects, through: :campaigns
  belongs_to :company

  attr_accessor :frontend_id

  def split_dupliacte_assignments
    # all prospects within prospect pool that have been used are removed from all campaigns where they haven't been used
    # "Prospect::used" uses .joins(:prospect_campaign_associations), which joins on both the campaigns and prospects of the existing query that is generated by rails for propsects() in this class by the has_many() calls above.
    # This has the comfortable side effect of only retrieving prospects that are part of at least one campaign of this prospect pool, that have been used by at least one campaign of this prospect pool but ignoring any usage of a prospect by a campaign not part of this prospect pool
    prospects.used.each do |p|
      p.prospect_campaign_associations.where(campaign: campaigns).unused.delete_all
    end

    # the ordering by id exists to make testing easier, this could be any order

    # splitting blacklisted and not blacklisted prospects independently so each campaign gets an even share
    # of blacklisted and not-blacklisted prospects to avoid the sitution where two campaigns might have the same
    # amount of prospects but a very uneven amount of non-blacklisted prospects
    remove_duplicate_assignments_from(
      prospects.assigned_to_multiple_campaigns_within_pool(self).unused.blacklisted.order(:id)
    )
    remove_duplicate_assignments_from(
      prospects.assigned_to_multiple_campaigns_within_pool(self).unused.not_blacklisted.order(:id)
    )
  end

  # Removes dupliacte assignments 50/50
  def remove_duplicate_assignments_from(dups)
    cmps = campaigns.order(:id)
    cmps = cmps.reject{ |c|
      c.unused_prospects.empty?
    }
    return if dups.empty? || cmps.empty?

    cmps = cmps.to_a


    campaign_combinations = (2..cmps.size).flat_map{ |size| cmps.combination(size).to_a }.to_a.sort_by(&:size).reverse

    campaign_combinations.each_with_index do |campaign_combo, combo_index|
      assigned_to_all = dups.assigned_to_all(campaign_combo)
      next if assigned_to_all.blank?

      GC.start if combo_index % 10 == 0

      assigned_to_all.in_groups_of((assigned_to_all.size / campaign_combo.size.to_f).ceil, false).each_with_index do |dup_group, i|
        dup_group.each do |prospect|
          prospect.prospect_campaign_associations.where(campaign: campaign_combo).where.not(campaign: campaign_combo[i]).delete_all
        end
      end
    end
  end
end
