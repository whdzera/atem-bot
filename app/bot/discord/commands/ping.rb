module Bot::DiscordCommands
  module Ping
    def self.load(bot)
      bot.register_application_command(
        :ping,
        'Check latency bot',
        server_id: ENV['guild_id_discord']
      )

      bot.application_command(:ping) do |event|
        begin
          start = Time.now
          event.defer
          latency = ((Time.now - start) * 1000).round

          event.edit_response(content: "🏓 Pong! Latency: #{latency}ms")
        rescue => e
          puts "[ERROR] Ping command failed: #{e.message}"
          event.respond(
            content: '⚠️ An error occurred while processing the command.'
          )
        end
      end
    end
  end
end
