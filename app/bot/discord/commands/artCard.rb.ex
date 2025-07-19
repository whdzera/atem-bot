module Bot::DiscordCommands
  module ArtCard
    def self.load(bot)
      bot.register_application_command(
        :art name,
        'Search Yu-Gi-Oh! card picture'
      ) do |cmd|
        cmd.string('name', 'Enter card name to search', required: true)
      end

      bot.application_command(:art name) do |event|
        card_name = event.options['name']
        begin
          event.defer(ephemeral: false)

          card_match = Ygoprodeck::Match.is(card_name)
          card_data = Ygoprodeck::Fname.is(card_match)

          if card_data.nil? || card_data['id'].nil?
            send_not_found_embed(event, card_name)
          else
            send_card_embed(event, card_data)
          end
        rescue => e
          puts "[ERROR_API : #{Time.now}] #{e.message}"
          event.edit_response(
            content: "⚠️ An error occurred while searching for '#{card_name}'"
          )
        end
      end
    end

    NOT_FOUND_IMAGE = 'https://i.imgur.com/lPSo3Tt.jpg'

    private

    def self.send_not_found_embed(event, card_name)
      event.edit_response do |builder|
        builder.content = ''
        builder.add_embed do |embed|
          embed.colour = 0xff1432
          embed.description = "**'#{card_name}' not found**"
          embed.image =
            Discordrb::Webhooks::EmbedImage.new(url: NOT_FOUND_IMAGE)
        end
      end
    end

    def self.send_card_embed(event, card_data)
      return if card_data.nil?

      type = card_data['type']
      if is_monster_card?(type)
        send_monster_embed(event, card_data)
      else
        send_non_monster_embed(event, card_data)
      end
    end

    def self.is_monster_card?(type)
      MONSTER_TYPES.key?(type)
    end

    def self.send_monster_embed(event, card_data)
      id = card_data['id']
      name = card_data['name']
      type = card_data['type']
      attribute = card_data['attribute']
      level = card_data['level']
      race = card_data['race']
      desc = card_data['desc']
      atk = card_data['atk']
      def_val = card_data['def']
      pict = Ygoprodeck::Image.is(id)

      ban_ocg = card_data.dig('banlist_info', 'ban_ocg') || 'Unlimited'
      ban_tcg = card_data.dig('banlist_info', 'ban_tcg') || 'Unlimited'

      type_info = MONSTER_TYPES[type]
      about = "[ #{race} #{type_info[:suffix]} ]"

      event.edit_response do |builder|
        builder.content = ''
        builder.add_embed do |embed|
          embed.colour = type_info[:color]
          embed.add_field(
            name: "**#{name}**",
            value:
              "**Limit :** **OCG:** #{ban_ocg} | **TCG:** #{ban_tcg}\n**Type:** #{type}\n**Attribute:** #{attribute}\n**Level:** #{level}"
          )
          embed.add_field(name: about, value: desc)
          embed.add_field(name: 'ATK', value: atk.to_s, inline: true)
          embed.add_field(name: 'DEF', value: def_val.to_s, inline: true)
          embed.image = Discordrb::Webhooks::EmbedImage.new(url: pict)
        end
      end
    end

    def self.send_non_monster_embed(event, card_data)
      id = card_data['id']
      name = card_data['name']
      type = card_data['type']
      race = card_data['race']
      desc = card_data['desc']
      pict = Ygoprodeck::Image.is(id)

      event.edit_response do |builder|
        builder.content = ''
        builder.add_embed do |embed|
          embed.colour = NON_MONSTER_TYPES[type][:color]
          embed.add_field(
            name: "**#{name}**",
            value: "**Type:** #{type}\n**Property:** #{race}"
          )
          embed.add_field(name: 'Effect', value: desc)
          embed.image = Discordrb::Webhooks::EmbedImage.new(url: pict)
        end
      end
    end
  end
end
