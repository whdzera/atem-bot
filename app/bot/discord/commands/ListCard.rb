module Bot::DiscordCommands
  module ListCard
    NUMBER_EMOJIS = %w[1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣ 6️⃣ 7️⃣ 8️⃣ 9️⃣ 🔟]
    ITEMS_PER_PAGE = 5
    MAX_RESULTS = 20
    EMBED_COLOR = 0xff8040
    NAVIGATION_EMOJIS = { prev_page: '⬅️', next_page: '➡️' }

    MONSTER_TYPES = {
      'Normal Monster' => {
        color: 0xdac14c,
        suffix: ''
      },
      'Normal Tuner Monster' => {
        color: 0xdac14c,
        suffix: '/ Tuner'
      },
      'Effect Monster' => {
        color: 0xa87524,
        suffix: '/ Effect'
      },
      'Flip Effect Monster' => {
        color: 0xa87524,
        suffix: '/ Flip / Effect'
      },
      'Flip Tuner Effect Monster' => {
        color: 0xa87524,
        suffix: '/ Flip / Tuner / Effect'
      },
      'Tuner Monster' => {
        color: 0xa87524,
        suffix: '/ Tuner / Effect'
      },
      'Toon Monster' => {
        color: 0xa87524,
        suffix: '/ Toon / Effect'
      },
      'Gemini Monster' => {
        color: 0xa87524,
        suffix: '/ Gemini / Effect'
      },
      'Spirit Monster' => {
        color: 0xa87524,
        suffix: '/ Spirit / Effect'
      },
      'Union Effect Monster' => {
        color: 0xa87524,
        suffix: '/ Union / Effect'
      },
      'Union Tuner Effect Monster' => {
        color: 0xa87524,
        suffix: '/ Union / Tuner / Effect'
      },
      'Ritual Monster' => {
        color: 0x293cbd,
        suffix: '/ Ritual'
      },
      'Ritual Effect Monster' => {
        color: 0x293cbd,
        suffix: '/ Ritual / Effect'
      },
      'Fusion Monster' => {
        color: 0x9115ee,
        suffix: '/ Fusion / Effect'
      },
      'Synchro Monster' => {
        color: 0xfcfcfc,
        suffix: '/ Synchro / Effect'
      },
      'Synchro Pendulum Effect Monster' => {
        color: 0xfcfcfc,
        suffix: '/ Synchro / Pendulum / Effect'
      },
      'Synchro Tuner Monster' => {
        color: 0xfcfcfc,
        suffix: '/ Synchro / Tuner / Effect'
      },
      'XYZ Monster' => {
        color: 0x252525,
        suffix: '/ XYZ / Effect'
      },
      'XYZ Pendulum Effect Monster' => {
        color: 0x252525,
        suffix: '/ XYZ / Pendulum / Effect'
      },
      'Pendulum Effect Monster' => {
        color: 0x84b870,
        suffix: '/ Pendulum / Effect'
      },
      'Pendulum Flip Effect Monster' => {
        color: 0x84b870,
        suffix: '/ Pendulum / Flip / Effect'
      },
      'Pendulum Normal Monster' => {
        color: 0x84b870,
        suffix: '/ Pendulum'
      },
      'Pendulum Tuner Effect Monster' => {
        color: 0x84b870,
        suffix: '/ Pendulum / Tuner / Effect'
      },
      'Pendulum Effect Fusion Monster' => {
        color: 0x84b870,
        suffix: '/ Pendulum / Effect / Fusion'
      },
      'Link Monster' => {
        color: 0x293cbd,
        suffix: '/ Link / Effect'
      }
    }

    NON_MONSTER_TYPES = {
      'Spell Card' => {
        color: 0x258b5c
      },
      'Trap Card' => {
        color: 0xc51a57
      },
      'Skill Card' => {
        color: 0x252525
      }
    }

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
            send_no_results_embed(event, search_term)
          else
            # Store results in a hash that we can access later
            user_id = event.user.id
            @@search_cache ||= {}
            @@search_cache[user_id] = {
              search_term: search_term,
              results: search_results,
              current_page: 0,
              total_pages: (search_results.length.to_f / ITEMS_PER_PAGE).ceil,
              message_id: nil
            }

            message = display_page(event, search_term, user_id)
            setup_reaction_handler(event, message)
          end
          nil
        end
      end
    end

    private

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

    def self.send_no_results_embed(event, search_term)
      event.channel.send_embed do |embed|
        embed.colour = EMBED_COLOR
        embed.add_field(
          name: "0 card matches for ``#{search_term}``",
          value: 'Try again aibou..',
          inline: true
        )
      end
    end

    def self.display_page(event, search_term, user_id)
      cache = @@search_cache[user_id]
      results = cache[:results]
      current_page = cache[:current_page]
      total_pages = cache[:total_pages]

      start_index = current_page * ITEMS_PER_PAGE
      end_index = [start_index + ITEMS_PER_PAGE - 1, results.length - 1].min

      cards_on_page = results[start_index..end_index]

      card_list = []
      cards_on_page.each_with_index do |card, index|
        number = index + 1
        number_str = number == 10 ? '0' : number.to_s
        card_list << "#{number_str}. #{card['name']}"
      end

      message =
        event.channel.send_embed do |embed|
          embed.colour = EMBED_COLOR
          embed.add_field(
            name:
              "#{results.length} card matches for ``#{search_term}`` (Page #{current_page + 1}/#{total_pages})",
            value: card_list.join("\n"),
            inline: true
          )
          embed.footer =
            Discordrb::Webhooks::EmbedFooter.new(
              text:
                'React with a number to see details for that card, or ⬅️ ➡️ to navigate pages'
            )
        end

      # Add navigation reactions if needed
      add_navigation_reactions(message, current_page, total_pages)

      # Add number reactions for cards on this page
      add_reaction_numbers(message, cards_on_page.length)

      message
    end

    def self.add_navigation_reactions(message, current_page, total_pages)
      begin
        # Add previous page reaction if not on first page
        message.react(NAVIGATION_EMOJIS[:prev_page]) if current_page > 0
        sleep(0.5)

        # Add next page reaction if not on last page
        if current_page < total_pages - 1
          message.react(NAVIGATION_EMOJIS[:next_page])
        end
        sleep(0.5)
      rescue => e
        puts "Error adding navigation reactions: #{e.message}"
      end
    end

    def self.add_reaction_numbers(message, count)
      count = [count, ITEMS_PER_PAGE].min

      begin
        count.times do |i|
          begin
            case i
            when 0
              message.react("1\u20e3") # 1️⃣
            when 1
              message.react("2\u20e3") # 2️⃣
            when 2
              message.react("3\u20e3") # 3️⃣
            when 3
              message.react("4\u20e3") # 4️⃣
            when 4
              message.react("5\u20e3") # 5️⃣
            when 5
              message.react("6\u20e3") # 6️⃣
            when 6
              message.react("7\u20e3") # 7️⃣
            when 7
              message.react("8\u20e3") # 8️⃣
            when 8
              message.react("9\u20e3") # 9️⃣
            when 9
              message.react("0\u20e3") # 0️⃣
            end

            sleep(0.5)
          rescue => e
            puts "Failed to add reaction #{i + 1}: #{e.message}"
          end
        end
      rescue => e
        puts "Error in reaction setup: #{e.message}"
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

          # Handle navigation reactions
          if reaction == NAVIGATION_EMOJIS[:prev_page] &&
               cache[:current_page] > 0
            cache[:current_page] -= 1
            message.delete
            display_page(event, '', user_id)
            next false
          elsif reaction == NAVIGATION_EMOJIS[:next_page] &&
                cache[:current_page] < cache[:total_pages] - 1
            cache[:current_page] += 1
            message.delete
            display_page(event, '', user_id)
            next false
          end

          # Handle number reactions
          if reaction.match(/^[0-9]\u20e3$/)
            num = reaction[0].to_i
            index = num == 0 ? 9 : num - 1

            # Calculate the actual index in the full results array
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
        card_id = card['id']
        card_data = Ygoprodeck::Fname.is(card['name'])

        if card_data && card_data['id']
          send_card_embed(event, card_data)
        else
          event.channel.send_message(
            "Could not find detailed information for #{card['name']}"
          )
        end
      rescue => e
        event.channel.send_message("Error fetching card details: #{e.message}")
      end
    end

    def self.send_card_embed(event, card_data)
      return if card_data.nil?

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

      event.channel.send_embed do |embed|
        embed.colour = type_info[:color]
        embed.add_field name: "**#{name}**",
                        value:
                          "**Limit :** **OCG:** #{ban_ocg} | **TCG:** #{ban_tcg}\n**Type:** #{type}\n**Attribute:** #{attribute}\n**Level:** #{level}"
        embed.add_field name: about, value: desc
        embed.add_field name: 'ATK', value: atk.to_s, inline: true
        embed.add_field name: 'DEF', value: def_val.to_s, inline: true
        embed.image = Discordrb::Webhooks::EmbedImage.new(url: pict)
      end
    end

    def self.send_non_monster_embed(event, card_data)
      id = card_data['id']
      name = card_data['name']
      type = card_data['type']
      race = card_data['race']
      desc = card_data['desc']
      pict = Ygoprodeck::Image.is(id)

      event.channel.send_embed do |embed|
        embed.colour = NON_MONSTER_TYPES[type][:color]
        embed.add_field name: "**#{name}**",
                        value: "**Type:** #{type}\n**Property:** #{race}"
        embed.add_field name: 'Effect', value: desc
        embed.image = Discordrb::Webhooks::EmbedImage.new(url: pict)
      end
    end
  end
end
