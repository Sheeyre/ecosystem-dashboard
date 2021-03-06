class SearchController < ApplicationController
  def index
    @page_title = "Tracked Searches"
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).includes(:search_query)

    @scope = @scope.where(repository_full_name: params[:repository_full_name]) if params[:repository_full_name].present?
    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?
    @scope = @scope.where(org: params[:org]) if params[:org].present?

    @pagy, @search_results = pagy(@scope.order('created_at desc'))

    respond_to do |format|
      format.html do
        @repos = @scope.unscope(where: :repository_full_name).group(:repository_full_name).count
        @kinds = @scope.unscope(where: :kind).group(:kind).count
        @orgs = @scope.unscope(where: :org).group(:org).count
      end
      format.rss do
        render 'index', :layout => false
      end
      format.json do
        render json: @search_results
      end
    end
  end

  def highlights
    @range = (params[:range].presence || 7).to_i
    @scope = SearchResult.this_period(@range).includes(:search_query)

    @scope = @scope.where(kind: params[:kind]) if params[:kind].present?

    @known_orgs = Organization.all.pluck(:name)
    @known_contributors = Contributor.all.pluck(:github_username)
    @known_owners = @known_orgs + @known_contributors
    @orgs = @scope.group_by(&:org).reject{|k,v| v.length < 2}.reject{|k,v| @known_owners.include?(k) }.sort_by{|k,v| -v.group_by(&:repository_full_name).length }

    @kinds = @scope.unscope(where: :kind).group(:kind).count
  end
end
