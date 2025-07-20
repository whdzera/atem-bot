module Bot::DiscordCommands
  module Info
    def self.load(bot)
      bot.register_application_command(:info, 'Show information Atem Bot')

      bot.application_command(:info) do |event|
        begin
          event.defer(ephemeral: false)

          event.edit_response(
            embeds: [
              {
                color: 0xff8040,
                title: '**Atem bot Information**',
                fields: [{ name: 'details', value: <<~INFO.strip }]
                      **Name**      : Atem  
                      **Version**   : 1.1.0  
                      **Developer** : [@whdzera](https://github.com/whdzera)  
                      **Written**   : Ruby Language (discordrb)  
                    INFO
              }
            ]
          )
        rescue => e
          puts "[ERROR] Info command failed: #{e.message}"
          begin
            event.respond(
              content: 'Error while showing bot info.',
              ephemeral: false
            )
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
