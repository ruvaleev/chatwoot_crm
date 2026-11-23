# Calls to Evolution API (https://doc.evolution-api.com, v2.3.7) for our WhatsApp numbers.
# Fails loudly: an unreachable or misconfigured Evolution is a setup problem, not a state to hide.
class Custom::Whatsapp::EvolutionClient
  def instances
    request(:get, '/instance/fetchInstances')
  end

  def create(payload)
    request(:post, '/instance/create', body: payload.to_json)
  end

  # Connection state when linked, QR code data (`base64`) otherwise.
  def connect(name)
    request(:get, "/instance/connect/#{name}")
  end

  def state(name)
    request(:get, "/instance/connectionState/#{name}").dig('instance', 'state')
  end

  # Unlinks the phone; the instance and the chat history stay.
  def logout(name)
    request(:delete, "/instance/logout/#{name}")
  end

  private

  def request(method, path, body: nil)
    response = HTTParty.send(method, "#{ENV.fetch('EVOLUTION_API_URL')}#{path}",
                             body: body, headers: { 'apikey' => ENV.fetch('EVOLUTION_API_KEY'), 'Content-Type' => 'application/json' })
    raise "Evolution API #{method.upcase} #{path} failed: #{response.code} #{response.body}" unless response.success?

    response.parsed_response
  end
end
