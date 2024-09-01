require 'sinatra'
require 'net/http'
require 'json'
require 'dotenv/load' # Load environment variables from .env file

# Force HTTPS in production
configure :production do
  require 'rack-ssl-enforcer'
  use Rack::SslEnforcer
end

# Ensure secure headers
before do
  headers 'Content-Security-Policy' => "default-src 'self'",
          'X-Content-Type-Options' => 'nosniff',
          'X-Frame-Options' => 'DENY',
          'X-XSS-Protection' => '1; mode=block'
end

# Home Route
get '/' do
  "Welcome to the Jenkins Integration App"
end

# Fetch Jenkins Job Status
get '/job/:job_name' do
  job_name = params[:job_name]
  jenkins_response = fetch_jenkins_job(job_name)
  if jenkins_response
    "Job Status for #{job_name}: #{jenkins_response['color']}"
  else
    "Error fetching job status."
  end
end

# Fetch Jenkins Job Status Helper Method
def fetch_jenkins_job(job_name)
  uri = URI("https://#{ENV['JENKINS_URL']}/job/#{job_name}/api/json")
  req = Net::HTTP::Get.new(uri)
  req.basic_auth(ENV['JENKINS_USER'], ENV['JENKINS_API_TOKEN'])

  begin
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)
    else
      nil
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    nil
  end
end

# 404 Route
not_found do
  "Page not found"
end
