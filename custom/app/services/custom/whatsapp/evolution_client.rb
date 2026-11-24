# Calls to Evolution API (https://doc.evolution-api.com, v2.3.7) for our WhatsApp numbers.
# Fails loudly: an unreachable or misconfigured Evolution is a setup problem, not a state to hide.
class Custom::Whatsapp::EvolutionClient
  # The chat header asks for the number state on every open: a hung Evolution must not hold Puma threads for a minute.
  TIMEOUT_SECONDS = 10

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

  # Reopens the connection of a linked number without a new QR code.
  def restart(name)
    request(:post, "/instance/restart/#{name}")
  end

  # Unlinks the phone; the instance and the chat history stay.
  def logout(name)
    request(:delete, "/instance/logout/#{name}")
  end

  private

  def request(method, path, body: nil)
    response = HTTParty.send(method, "#{ENV.fetch('EVOLUTION_API_URL')}#{path}",
                             body: body, timeout: TIMEOUT_SECONDS,
                             headers: { 'apikey' => ENV.fetch('EVOLUTION_API_KEY'), 'Content-Type' => 'application/json' })
    raise "Evolution API #{method.upcase} #{path} failed: #{response.code} #{response.body}" unless response.success?

    response.parsed_response
  end
end
