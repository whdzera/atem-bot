module Bot::DiscordCommands
  module Ping
    def self.load(bot)
      bot.register_application_command(:ping, 'Check latency bot')

      bot.application_command(:ping) do |event|
        begin
          start = Time.now
          event.defer(ephemeral: false)
          latency = ((Time.now - start) * 1000).round

          event.edit_response(
            embeds: [
              {
                color: 0xff8040,
                fields: [
                  {
                    name: '**Pong!**',
                    value: "Latency: #{latency}ms",
                    inline: true
                  }
                ]
              }
            ]
          )
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
