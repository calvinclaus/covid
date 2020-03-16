module Backend
  class CompanyFormController < Backend::BackendController
    def show
      @company = Company.includes(:prospect_pools, :searches, campaigns: %i[linked_in_account prospect_pool_campaign_associations campaign_search_associations]).find(params[:id])
      @linked_in_accounts = LinkedInAccount.all
      if @company.prospect_pools.blank?
        @company.prospect_pools.create!(name: "Default")
      end
    end

    # TODO/IDEA
    # CompanyFormServiceModel
    # Die gegliederten blöcke dieser methode als einzlene methoden im ServiceModel
    # CompanyForm.update_company_from_hash(hash) oder company = CompanyForm.create!(params)
    def update
      @company = Company.includes(:prospect_pools, :searches, campaigns: %i[linked_in_account prospect_pool_campaign_associations campaign_search_associations]).find(params[:id])
      @company.update_attribute(:prospect_distribution_status, "UNSYNCED")

      @linked_in_accounts = []
      linked_in_accounts = permitted_linked_in_account_params
      linked_in_accounts.each do |account_params|
        if account_params[:id].present?
          account = LinkedInAccount.find(account_params[:id])
          account.update(account_params)
          @linked_in_accounts << account
        else
          @linked_in_accounts << LinkedInAccount.create(account_params)
        end
      end

      hash = permitted_company_params.to_h.with_indifferent_access

      hash[:searches] ||= []
      hash[:searches].each do |search|
        if search[:linked_in_account_id].present?
          acc = @linked_in_accounts.find{ |a| a.frontend_id == search[:linked_in_account_id] }
          search[:linked_in_account_id] = acc.id if acc.present?
        end
      end


      @company.transaction do
        hash[:campaigns] ||= []
        hash[:campaigns].each do |campaign|
          if campaign[:linked_in_account_id].present?
            acc = @linked_in_accounts.find{ |a| a.frontend_id == campaign[:linked_in_account_id] }
            campaign[:linked_in_account_id] = acc.id if acc.present?
          end

          if @company.campaigns.where(id: campaign[:id]).first.present?
            @company.campaigns.where(id: campaign[:id]).first.campaign_search_associations.destroy_all
          end
          if campaign[:campaign_search_associations].present?
            campaign[:campaign_search_associations] = campaign[:campaign_search_associations].map{ |assoc|
              {search_id: assoc[:search_id]}
            }.uniq
          end

          if @company.campaigns.where(id: campaign[:id]).first.present?
            @company.campaigns.where(id: campaign[:id]).first.prospect_pool_campaign_associations.destroy_all
          end


          next unless campaign[:prospect_pool_campaign_associations].present?

          campaign[:prospect_pool_campaign_associations] = campaign[:prospect_pool_campaign_associations].map{ |assoc|
            {prospect_pool_id: assoc[:prospect_pool_id]}
          }.uniq
        end
        @company.reload
        if @company.update(adapt_attribute_names(hash))
          @company.schedule_prospect_distribution if params[:compute].present?
        else
          raise ActiveRecord::Rollback
        end
      end
      # as we are caching we need to set updated at to now for non persisted searches (not saved due to failed validation)
      @company.searches.each do |search|
        search.updated_at = Time.current unless search.updated_at.present?
      end
    end

    def adapt_attribute_names(params)
      params = params.to_h.with_indifferent_access
      add_attr(params, :searches)
      add_attr(params, :credit_bookings)
      add_attr(params, :blacklist_imports)
      params[:campaigns_attributes] = adapt_campaigns(params.delete(:campaigns))
      add_attr(params, :prospect_pools)
      params
    end

    def adapt_campaigns(campaigns)
      campaigns.map do |campaign|
        add_attr(campaign, :prospect_pool_campaign_associations)
        add_attr(campaign, :campaign_search_associations)
        add_attr(campaign, :linked_in_profile_scraper)
        campaign
      end
    end

    def add_attr(hash, key_without_attr)
      hash[(key_without_attr.to_s + "_attributes").to_sym] = hash.delete(key_without_attr) if hash.key?(key_without_attr)
    end

    private

    def permitted_linked_in_account_params
      params.fetch(:linked_in_accounts, []).map do |p|
        p.permit(%i[
          id
          frontend_id
          name
          email
          li_at
        ])
      end
    end

    def permitted_company_params
      params.require(:company).permit(
        :id,
        :name,
        :reseller_id,
        credit_bookings: %i[
          id
          frontend_id
          name
          booking_date
          credit_amount
          _destroy
        ],
        searches: %i[
          id
          name
          notes
          frontend_id
          search_result_csv_url
          uses_csv_import
          linked_in_search_url
          linked_in_account_id
          linked_in_result_limit
          should_redo
          should_clear
        ],
        campaigns: [
          :id,
          :frontend_id,
          :name,
          :next_milestone,
          :status,
          :notes,
          :started_at,
          :target_audience_size,
          :linked_in_account_id,
          :prospect_pools,
          :message,
          :should_save_to_phantombuster,
          :manual_control,
          :manual_daily_request_target,
          :manual_people_count_to_keep,
          :script_type,
          :timezone,
          {prospect_pool_campaign_associations: %i[id prospect_pool_id frontend_id]},
          {campaign_search_associations: %i[id search_id frontend_id]},
          {linked_in_profile_scraper: %i[id daily_scraping_target active]},
          follow_ups: %i[message days_delay],
          segments: %i[date name],
          follow_up_stages_to_count_as_credit_use: [],
        ],
        prospect_pools: %i[
          id
          frontend_id
          name
        ],
        blacklist_imports: %i[
          id
          frontend_id
          csv_url
          type
        ],
        resold_company_ids: [],
      )
    end
  end
end
