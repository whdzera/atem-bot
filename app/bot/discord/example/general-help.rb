module Bot::DiscordCommands
  module Help
    extend Discordrb::Commands::CommandContainer

    command(:help) do |event|
      event.channel.send_embed do |embed|
        embed.colour = 0xff8040
        embed.add_field name: '**information bot**', value: '``::info``'
        embed.add_field name: '**ping**', value: '``::ping``'
        embed.add_field name: '**search card**', value: '``::dark magician::``'
        embed.add_field name: '**search card (list)**',
                        value: '``::src magician``'
        embed.add_field name: '**random card **', value: '``::random``'
      end
    end
  end
end
