class Searchlist
  MAX_RESULTS = 25
  RESULTS_PER_PAGE = 5

  def self.message(from, page = 1)
    cards = Ygoprodeck::List.is(from)

    if cards.empty? || cards[0]['id'].nil?
      return(
        {
          text: "0 card matches for *#{from}*\nTry again, aibou...",
          keyboard: nil
        }
      )
    end

    total_cards = cards.size > MAX_RESULTS ? MAX_RESULTS : cards.size
    total_pages = (total_cards.to_f / RESULTS_PER_PAGE).ceil
    page = [[page.to_i, 1].max, total_pages].min

    start_index = (page - 1) * RESULTS_PER_PAGE
    end_index = [start_index + RESULTS_PER_PAGE - 1, total_cards - 1].min

    display_cards = cards.slice(start_index..end_index)

    message =
      "#{total_cards} card matches for *#{from}* (Page #{page}/#{total_pages})\n\n"
    message +=
      display_cards
        .each_with_index
        .map { |card, i| "#{start_index + i + 1}. #{card['name']}" }
        .join("\n")

    # Create inline keyboard
    keyboard = []

    # Add card selection buttons
    display_cards.each_with_index do |card, i|
      selection_number = start_index + i + 1
      keyboard << [
        {
          text: "#{selection_number}",
          callback_data: "select_#{selection_number}_#{from}"
        }
      ]
    end

    # Add navigation buttons
    nav_row = []
    if page > 1
      nav_row << { text: '⬅️ Previous', callback_data: "prev_#{from}_#{page}" }
    end
    if page < total_pages
      nav_row << { text: '➡️ Next', callback_data: "next_#{from}_#{page}" }
    end
    keyboard << nav_row unless nav_row.empty?

    # Add search button
    keyboard << [
      { text: '🔍 Search within results', callback_data: "search_#{from}" }
    ]

    { text: message, keyboard: keyboard }
  end

  def self.filter_list(from, keyword, page = 1)
    cards = Ygoprodeck::List.is(from)

    if cards.empty? || cards[0]['id'].nil?
      return { text: "0 card matches for *#{from}*", keyboard: nil }
    end

    filtered_cards =
      cards
        .first(MAX_RESULTS)
        .select { |card| card['name'].downcase.include?(keyword.downcase) }

    if filtered_cards.empty?
      return(
        {
          text: "No matching cards with *#{keyword}*",
          keyboard: [
            [{ text: 'Back to all results', callback_data: "back_#{from}" }]
          ]
        }
      )
    end

    total_cards = filtered_cards.size
    total_pages = (total_cards.to_f / RESULTS_PER_PAGE).ceil
    page = [[page.to_i, 1].max, total_pages].min

    start_index = (page - 1) * RESULTS_PER_PAGE
    end_index = [start_index + RESULTS_PER_PAGE - 1, total_cards - 1].min

    display_cards = filtered_cards.slice(start_index..end_index)

    message =
      "#{total_cards} cards with *#{keyword}* (Page #{page}/#{total_pages})\n\n"
    message +=
      display_cards
        .each_with_index
        .map { |card, i| "#{start_index + i + 1}. #{card['name']}" }
        .join("\n")

    # Create inline keyboard
    keyboard = []

    # Add card selection buttons
    display_cards.each_with_index do |card, i|
      selection_number = start_index + i + 1
      keyboard << [
        {
          text: "#{selection_number}",
          callback_data: "select_#{selection_number}_#{from}_#{keyword}"
        }
      ]
    end

    # Add navigation buttons
    nav_row = []
    if page > 1
      nav_row << {
        text: '⬅️ Previous',
        callback_data: "prev_#{from}_#{page}_#{keyword}"
      }
    end
    if page < total_pages
      nav_row << {
        text: '➡️ Next',
        callback_data: "next_#{from}_#{page}_#{keyword}"
      }
    end
    keyboard << nav_row unless nav_row.empty?

    # Add search and back buttons
    keyboard << [
      { text: '🔍 New search', callback_data: "search_#{from}_#{keyword}" },
      { text: 'Back to all', callback_data: "back_#{from}" }
    ]

    { text: message, keyboard: keyboard }
  end

  def self.select_card(from, selection, keyword = nil)
    cards = Ygoprodeck::List.is(from)

    if cards.empty? || cards[0]['id'].nil?
      return { text: "No cards found for *#{from}*", keyboard: nil }
    end

    # If we have a keyword, filter the cards first
    if keyword
      cards =
        cards
          .first(MAX_RESULTS)
          .select { |card| card['name'].downcase.include?(keyword.downcase) }
      if cards.empty?
        return(
          {
            text: "No matching cards with *#{keyword}*",
            keyboard: [
              [{ text: 'Back to all results', callback_data: "back_#{from}" }]
            ]
          }
        )
      end
    else
      cards = cards.first(MAX_RESULTS)
    end

    selection = selection.to_i

    if selection < 1 || selection > cards.size
      return(
        {
          text:
            "Invalid selection. Please choose a number between 1 and #{cards.size}.",
          keyboard: [
            [
              {
                text: 'Back to results',
                callback_data:
                  keyword ? "back_search_#{from}_#{keyword}" : "back_#{from}"
              }
            ]
          ]
        }
      )
    end

    selected_card = cards[selection - 1]

    # Format the card details
    message = "*#{selected_card['name']}*\n"
    message += "Type: #{selected_card['type'] || 'Unknown'}\n"
    message += "Level/Rank: #{selected_card['level']}\n" if selected_card[
      'level'
    ]
    message +=
      "ATK/DEF: #{selected_card['atk'] || '?'}/#{selected_card['def'] || '?'}\n" if selected_card[
      'atk'
    ] || selected_card['def']
    message += "Description: #{selected_card['desc']}"

    # Create keyboard for navigation back
    keyboard = [
      [
        {
          text: 'Back to results',
          callback_data:
            keyword ? "back_search_#{from}_#{keyword}" : "back_#{from}"
        }
      ]
    ]

    { text: message, keyboard: keyboard }
  end

  def self.process_callback(callback_data)
    # Parsing the callback data
    parts = callback_data.split('_')
    action = parts[0]

    case action
    when 'select'
      selection = parts[1]
      from = parts[2]
      keyword = parts[3] if parts.size > 3
      return select_card(from, selection, keyword)
    when 'prev'
      from = parts[1]
      current_page = parts[2].to_i
      keyword = parts[3] if parts.size > 3
      return(
        (
          if keyword
            filter_list(from, keyword, current_page - 1)
          else
            message(from, current_page - 1)
          end
        )
      )
    when 'next'
      from = parts[1]
      current_page = parts[2].to_i
      keyword = parts[3] if parts.size > 3
      return(
        (
          if keyword
            filter_list(from, keyword, current_page + 1)
          else
            message(from, current_page + 1)
          end
        )
      )
    when 'back'
      from = parts[1]
      return message(from)
    when 'back_search'
      from = parts[1]
      keyword = parts[2]
      return filter_list(from, keyword)
    when 'search'
      from = parts[1]
      keyword = parts[2] if parts.size > 2
      # Return a message asking for search input
      return(
        {
          text:
            "Please enter a keyword to search within the #{keyword ? 'filtered' : ''} results for *#{from}*",
          keyboard: [
            [
              {
                text: 'Cancel',
                callback_data:
                  keyword ? "back_search_#{from}_#{keyword}" : "back_#{from}"
              }
            ]
          ]
        }
      )
    end
  end

  def self.process_text_response(from, text, context = {})
    # If we're expecting a search keyword
    return filter_list(from, text) if context[:awaiting_search]

    # Try to parse as number for selection
    if text.match?(/^\d+$/)
      selection = text.to_i
      return select_card(from, selection, context[:keyword])
    end

    # Check if it's a page command
    if text.downcase.start_with?('page ')
      page = text.downcase.gsub('page ', '').to_i
      return(
        (
          if context[:keyword]
            filter_list(from, context[:keyword], page)
          else
            message(from, page)
          end
        )
      )
    end

    # Otherwise, treat it as a search keyword
    return filter_list(from, text)
  end
end
