namespace :issues do
  task sync_collabs: :environment do
    Organization.collaborator.pluck(:name).each do |org|
      Repository.sync_recently_active_repos(org)
    end
  end

  task sync_recent: :environment do
    Repository.sync_recently_active_internal_repos
    Issue.update_collab_labels
  end

  task sync_daily: :environment do
    ids = Issue.internal.state('open').where('last_synced_at < ? or last_synced_at is null', 1.day.ago).limit(1000).order('issues.last_synced_at asc nulls first, issues.updated asc').pluck(:id)
    Issue.where(id: ids).find_each(&:sync)
  end
end
