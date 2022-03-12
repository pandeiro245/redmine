class Timecrowd
  def me
    api_get('/api/v1/user')
  end

  def start(user_id, title, url)
    category_title = 'allotask'
    team_id = ENV['TIMECROWD_TEAM_ID']
    category_id = get_categories.select{|c| c['title'].upcase == category_title.upcase}.first['id']
    task_id = create_task(team_id, title, category_id, url)['id']
    start_task(user_id, task_id)
  end

  def create_task(team_id, title, category_id, url)
    params = {
      task: {
	title: title,
	parent_id: category_id,
        url: url
      }
    }
    api_post(
      "/api/v1/teams/#{team_id}/tasks", params
    )
  end

  def start_task(user_id, task_id)
    now = Time.zone.now
    working_user = working_users.select { |u| u['id'].to_i == user_id.to_i }.first

    if working_user.present?
      params = { time_entry: {
	stopped_at: now.to_i
      } }
      url = "/api/v1/time_entries/#{working_user['time_entry']['id']}"
      api_put(url, params)
    end
    params = {
      time_trackable_id: task_id,
      time_tracker_id: user_id,
      started_at: now
    }
    url = "/api/v1/tasks/#{task_id}/time_entries"

    api_post(url, { time_entry: params })
  end

  def working_users
    api_get('/api/v1/user/working_users')
  end

  def get_categories
    api_get('/api/v1/categories')
  end

  def api_get(path, params = {})
    api_request(:get, path, params)
  end

  def api_post(path, params = {})
    api_request(:post, path, params)
  end

  def api_put(path, params = {})
    api_request(:put, path, params)
  end

  def api_patch(path, params = {})
    api_request(:patch, path, params)
  end

  def api_delete(path, params = {})
    api_request(:delete, path, params)
  end

  def api_request(method, path, params = {})
    client.public_send(method, path, body: params).parsed
  end

  def client
    @client ||= OAuth2::AccessToken.new(
      OAuth2::Client.new(
	ENV.fetch('TIMECROWD_APP_ID') { Rails.application.credentials.timecrowd[:app_id] },
	ENV.fetch('TIMECROWD_SECRET') { Rails.application.credentials.timecrowd[:secret] },
	site: ENV.fetch('TIMECROWD_SITE', 'https://timecrowd.net')
      ), ENV['TIMECROWD_TOKEN']
    )
  end
end
