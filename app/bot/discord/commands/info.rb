module Bot::DiscordCommands
  module Info
    extend Discordrb::Commands::CommandContainer

    command(:info) do |event|
      event.channel.send_embed do |embed|
        embed.colour = 0xff8040
        embed.add_field name: '**Information Bot**',
                        value:
                          " **Name**    : Atem \n **Version**   : 1.1.0 \n **Developer** : [@whdzera](https://github.com/whdzera) \n **Written**   : Ruby Language (discordrb) \n **Link**      : invite bot "
      end
    end
  end
end
