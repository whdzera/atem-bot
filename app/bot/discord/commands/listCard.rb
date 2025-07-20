module Bot::DiscordCommands
  module ListCard
    NUMBER_EMOJIS = %w[1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣ 6️⃣ 7️⃣ 8️⃣ 9️⃣ 🔟]
    ITEMS_PER_PAGE = 5
    MAX_RESULTS = 20
    EMBED_COLOR = 0xff8040
    NAVIGATION_EMOJIS = { prev_page: '⬅️', next_page: '➡️' }

    def self.load(bot)
      bot.register_application_command(
        :list,
        'Search Yu-Gi-Oh! cards by name'
      ) do |cmd|
        cmd.string('name', 'Enter card name to search', required: true)
      end
      bot.application_command(:list) do |event|
        search_term = event.options['name']
        begin
          event.defer(ephemeral: false)
          search_results = perform_search(search_term)

          if search_results.empty?
            event.edit_response(
              embeds: [
                {
                  color: EMBED_COLOR,
                  fields: [
                    {
                      name: "0 card matches for ``#{search_term}``",
                      value: 'Try again aibou..',
                      inline: true
                    }
                  ]
                }
              ]
            )
          else
            user_id = event.user.id
            @@search_cache ||= {}
            @@search_cache[user_id] = {
              search_term: search_term,
              results: search_results,
              current_page: 0,
              total_pages: (search_results.length.to_f / ITEMS_PER_PAGE).ceil
            }

            display_page(event, search_term, user_id)
          end
        rescue => e
          puts "[ERROR] Search command failed: #{e.message}"
          event.edit_response(content: '⚠️ An error occurred while searching.')
        end
      end
    end

    def self.perform_search(search_term)
      results = []

      begin
        search_list = Ygoprodeck::List.is(search_term)

        if search_list.nil? || search_list.empty? || search_list[0]['id'].nil?
          return []
        end

        search_list
          .first(MAX_RESULTS)
          .each { |card| results << card if card && card['name'] }
      rescue => e
        puts "Error searching for cards: #{e.message}"
      end

      results
    end

    def self.display_page(event, search_term, user_id)
      cache = @@search_cache[user_id]
      results = cache[:results]
      current_page = cache[:current_page]
      total_pages = cache[:total_pages]

      start_index = current_page * ITEMS_PER_PAGE
      end_index = [start_index + ITEMS_PER_PAGE - 1, results.length - 1].min
      cards_on_page = results[start_index..end_index]

      card_list =
        cards_on_page
          .each_with_index
          .map do |card, index|
            number = index + 1
            number_str = number == 10 ? '0' : number.to_s
            "#{number_str}. #{card['name']}"
          end
          .join("\n")

      # Edit embed yang sudah di-defer
      event.edit_response(
        embeds: [
          {
            color: EMBED_COLOR,
            fields: [
              {
                name:
                  "#{results.length} card matches for ``#{search_term}`` (Page #{current_page + 1}/#{total_pages})",
                value: card_list,
                inline: true
              }
            ],
            footer: {
              text:
                'React with a number to see details for that card, or ⬅️ ➡️ to navigate pages'
            }
          }
        ]
      )

      # Kirim message asli (yang akan kita kasih reaction)
      message =
        event.channel.send_message(
          'React below to select a card or change page.'
        )

      # Simpan ID pesan untuk keperluan reaksi
      @@search_cache[user_id][:message_id] = message.id

      add_navigation_reactions(message, current_page, total_pages)
      add_reaction_numbers(message, cards_on_page.length)
      setup_reaction_handler(event, message)
    end
    def self.add_navigation_reactions(message, current_page, total_pages)
      begin
        if current_page > 0
          message.react(NAVIGATION_EMOJIS[:prev_page])
          sleep(1.2)
        end

        if current_page < total_pages - 1
          message.react(NAVIGATION_EMOJIS[:next_page])
          sleep(1.2)
        end
      rescue => e
        puts "[WARN] Navigation emoji rate-limited: #{e.message}"
      end
    end

    def self.add_reaction_numbers(message, count)
      count = [count, ITEMS_PER_PAGE].min
      count.times do |i|
        emoji = NUMBER_EMOJIS[i]
        begin
          message.react(emoji)
          sleep(1.2) # ← Tambah delay supaya lebih aman
        rescue => e
          puts "[WARN] Reaction rate limit or failure: #{e.message}"
        end
      end
    end

    def self.setup_reaction_handler(event, message)
      event
        .bot
        .add_await!(
          Discordrb::Events::ReactionAddEvent,
          timeout: 300,
          message: message.id
        ) do |reaction_event|
          next true if reaction_event.user.bot_account
          next true if reaction_event.user.id != event.user.id

          user_id = reaction_event.user.id
          reaction = reaction_event.emoji.name
          cache = @@search_cache[user_id]

          if reaction == NAVIGATION_EMOJIS[:prev_page] &&
               cache[:current_page] > 0
            cache[:current_page] -= 1
            message.delete
            display_page(event, cache[:search_term], user_id)
            next false
          elsif reaction == NAVIGATION_EMOJIS[:next_page] &&
                cache[:current_page] < cache[:total_pages] - 1
            cache[:current_page] += 1
            message.delete
            display_page(event, cache[:search_term], user_id)
            next false
          elsif NUMBER_EMOJIS.include?(reaction)
            index = NUMBER_EMOJIS.index(reaction)
            actual_index = cache[:current_page] * ITEMS_PER_PAGE + index

            if actual_index < cache[:results].length
              selected_card = cache[:results][actual_index]
              display_card_details(event, selected_card)
            end
          end

          false
        end
    end

    def self.display_card_details(event, card)
      begin
        card_data = Ygoprodeck::Fname.is(card['name'])

        if card_data && card_data['id']
          send_card_embed(event, card_data)
        else
          event.channel.send_message(
            "Could not find details for #{card['name']}"
          )
        end
      rescue => e
        event.channel.send_message("Error fetching card details: #{e.message}")
      end
    end

    def self.send_card_embed(event, card_data)
      id = card_data['id']
      name = card_data['name']
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
      pict = Ygoprodeck::Image.is(card_data['id'])

      ban_ocg = card_data.dig('banlist_info', 'ban_ocg') || 'Unlimited'
      ban_tcg = card_data.dig('banlist_info', 'ban_tcg') || 'Unlimited'

      type_info = MONSTER_TYPES[card_data['type']]
      about = "[ #{card_data['race']} #{type_info[:suffix]} ]"

      event.channel.send_embed do |embed|
        embed.colour = type_info[:color]
        embed.add_field name: "**#{card_data['name']}**",
                        value:
                          "**Limit:** **OCG:** #{ban_ocg} | **TCG:** #{ban_tcg}\n" \
                            "**Type:** #{card_data['type']}\n" \
                            "**Attribute:** #{card_data['attribute']}\n" \
                            "**Level:** #{card_data['level']}"
        embed.add_field name: about, value: card_data['desc']
        embed.add_field name: 'ATK', value: card_data['atk'].to_s, inline: true
        embed.add_field name: 'DEF', value: card_data['def'].to_s, inline: true
        embed.image = { url: pict }
      end
    end

    def self.send_non_monster_embed(event, card_data)
      pict = Ygoprodeck::Image.is(card_data['id'])

      event.channel.send_embed do |embed|
        embed.colour = NON_MONSTER_TYPES[card_data['type']][:color]
        embed.add_field name: "**#{card_data['name']}**",
                        value:
                          "**Type:** #{card_data['type']}\n**Property:** #{card_data['race']}"
        embed.add_field name: 'Effect', value: card_data['desc']
        embed.image = { url: pict }
      end
    end
  end
end
