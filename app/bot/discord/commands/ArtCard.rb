module Bot::DiscordCommands
  module ArtCard
    def self.load(bot)
      bot.register_application_command(
        :art,
        'Search Art Yu-Gi-Oh! cards'
      ) do |cmd|
        cmd.subcommand(:name, 'Search Art by card name') do |sub|
          sub.string('input', 'Enter card name', required: true)
        end

        cmd.subcommand(:id, 'Search Art by card ID') do |sub|
          sub.string('input', 'Enter card ID', required: true)
        end
      end

      # Search by card name
      bot
        .application_command(:art)
        .subcommand(:name) do |event|
          card_name = event.options['input']
          begin
            event.defer(ephemeral: false)

            card_match = Ygoprodeck::Match.is(card_name)
            card_data = Ygoprodeck::Fname.is(card_match)

            if card_data.nil? || card_data['id'].nil?
              event.edit_response(
                embeds: [
                  {
                    color: 0xff1432,
                    description: "**'#{card_name}' not found**",
                    image: {
                      url: NOT_FOUND_IMAGE
                    }
                  }
                ]
              )
            else
              art_image = Ygoprodeck::Image_small.is(card_data['id'])
              event.edit_response(
                embeds: [
                  {
                    color: 0xff8040,
                    title: "**#{card_data['name']}**",
                    image: {
                      url: art_image
                    }
                  }
                ]
              )
            end
          rescue => e
            puts "[ERROR_API : #{Time.now}] #{e.message}"
            event.edit_response(
              content: "⚠️ An error occurred while searching for '#{card_name}'"
            )
          end
        end

      # Search by card ID
      bot
        .application_command(:art)
        .subcommand(:id) do |event|
          card_id = event.options['input']
          begin
            event.defer(ephemeral: false)

            card_data = Ygoprodeck::ID.is(card_id)

            if card_data.nil? || card_data['id'].nil?
              event.edit_response(
                embeds: [
                  {
                    color: 0xff1432,
                    description: "**ID '#{card_id}' not found**",
                    image: {
                      url: NOT_FOUND_IMAGE
                    }
                  }
                ]
              )
            else
              art_image = Ygoprodeck::Image_small.is(card_data['id'])
              event.edit_response(
                embeds: [
                  {
                    color: 0xff8040,
                    title: "**#{card_data['name']}**",
                    image: {
                      url: art_image
                    }
                  }
                ]
              )
            end
          rescue => e
            puts "[ERROR_API : #{Time.now}] #{e.message}"
            event.edit_response(
              content:
                "⚠️ An error occurred while searching for ID '#{card_id}'"
            )
          end
        end
    end

    NOT_FOUND_IMAGE = 'https://i.imgur.com/lPSo3Tt.jpg'
  end
end
