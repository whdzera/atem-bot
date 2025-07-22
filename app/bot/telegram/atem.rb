Dir[File.join(__dir__, 'commands/*.rb')].sort.each do |file|
  require_relative file
end

class Atem
  COMMAND_PREFIX = '/'.freeze

  COMMANDS = {
    start: %w[/start /welcome /help],
    info: ['/info'],
    ping: ['/ping'],
    card: ['/card'],
    random: ['/random'],
    search: ['/search']
    #searchlist: ['/searchlist']
  }.freeze

  def self.start
    logger = Logger.new($stdout)
    logger.level = Logger::INFO

    loop do
      begin
        logger.info "[#{Time.now}] Starting Telegram Bot..."
        Telegram::Bot::Client.run(TOKEN, allowed_updates: ['message']) do |bot|
          bot.listen do |message|
            next unless message.is_a?(Telegram::Bot::Types::Message)
            next unless message.text

            text = message.text.to_s.strip

            handle_message(bot, message, text)

            logger.info "Received from @#{message.from.username}: #{message.text}"
          end
        end
      rescue Telegram::Bot::Exceptions::ResponseError => e
        logger.error "[Telegram Error] #{e.message}"
        sleep 10
      rescue StandardError => e
        logger.error "[Unhandled Error] #{e.class}: #{e.message}"
        logger.error e.backtrace.join("\n")
        sleep 5
      end
    end
  end

  private

  def self.handle_message(bot, message, text)
    chat_id = message.chat.id

    case
    when COMMANDS[:start].include?(text)
      send_message(bot, chat_id, General.help)
    when COMMANDS[:info].include?(text)
      send_info_message(bot, chat_id)
    when COMMANDS[:ping].include?(text)
      start_time = Time.now
      msg = bot.api.send_message(chat_id: chat_id, text: 'Pinging...')
      end_time = Time.now
      latency = ((end_time - start_time) * 1000).round

      bot.api.edit_message_text(
        chat_id: chat_id,
        message_id: msg.message_id,
        text: "Pong! Latency: #{latency}ms"
      )
    when COMMANDS[:card].include?(text)
      send_message(bot, chat_id, '/card <name card>')
    when text.start_with?("#{COMMANDS[:card][0]} ")
      handle_card(bot, chat_id, text.sub("#{COMMANDS[:card][0]} ", ''))
    when COMMANDS[:random].include?(text)
      hit_random = Random.random_card

      bot.api.send_photo(
        chat_id: chat_id,
        photo: hit_random[:image],
        caption: hit_random[:message],
        parse_mode: 'Markdown'
      )
    when COMMANDS[:search].include?(text)
      send_message(bot, chat_id, '/search <name card>')
    when text.start_with?("#{COMMANDS[:search][0]} ")
      handle_search(bot, chat_id, text.sub("#{COMMANDS[:search][0]} ", ''))
    when text.include?('::')
      handle_shorthand_search(bot, chat_id, text)
    end
  end

  def self.send_message(bot, chat_id, text, parse_mode = 'Markdown')
    bot.api.send_message(chat_id: chat_id, text: text, parse_mode: parse_mode)
  end

  def self.send_info_message(bot, chat_id)
    callback = [
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: 'Source code',
        url: General.sourcecode
      )
    ]
    markup =
      Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [callback]
      )

    bot.api.send_message(
      chat_id: chat_id,
      text: General.info,
      parse_mode: 'Markdown',
      reply_markup: markup
    )
  end

  def self.handle_card(bot, chat_id, keyword)
    result = Card.message(keyword)

    if result[:success]
      bot.api.send_photo(
        chat_id: chat_id,
        photo: result[:image],
        caption: result[:caption],
        parse_mode: 'Markdown'
      )
    else
      send_message(bot, chat_id, result[:error])
    end
  end

  def self.handle_search(bot, chat_id, keyword)
    bot.api.send_photo(
      chat_id: chat_id,
      photo: Pict.link(keyword),
      caption: Search.message(keyword),
      parse_mode: 'Markdown'
    )
  end

  def self.handle_searchlist(bot, chat_id, keyword)
    send_message(bot, chat_id, Searchlist.message(keyword))
  end

  def self.handle_shorthand_search(bot, chat_id, text)
    if match = text.match(/::(.+)::/)
      keyword = match[1]
      handle_search(bot, chat_id, keyword)
    end
  end
end
