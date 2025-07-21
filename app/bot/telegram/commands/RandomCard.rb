class Random
  MONSTER_TYPES = [
    'Normal Monster',
    'Normal Tuner Monster',
    'Effect Monster',
    'Flip Effect Monster',
    'Flip Tuner Effect Monster',
    'Tuner Monster',
    'Toon Monster',
    'Gemini Monster',
    'Spirit Monster',
    'Union Effect Monster',
    'Union Tuner Effect Monster',
    'Ritual Monster',
    'Ritual Effect Monster',
    'Fusion Monster',
    'Synchro Monster',
    'Synchro Pendulum Effect Monster',
    'Synchro Tuner Monster',
    'XYZ Monster',
    'XYZ Pendulum Effect Monster',
    'Pendulum Effect Monster',
    'Pendulum Flip Effect Monster',
    'Pendulum Normal Monster',
    'Pendulum Tuner Effect Monster',
    'Pendulum Effect Fusion Monster',
    'Link Monster'
  ].freeze

  NON_MONSTER_TYPES = ['Spell Card', 'Trap Card', 'Skill Card'].freeze

  TYPE_DESCRIPTIONS = {
    'Normal Monster' => ->(race) { "[#{race}]" },
    'Normal Tuner Monster' => ->(race) { "[#{race} / Tuner]" },
    'Effect Monster' => ->(race) { "[#{race} / Effect]" },
    'Flip Effect Monster' => ->(race) { "[#{race} / Flip / Effect]" },
    'Flip Tuner Effect Monster' => ->(race) do
      "[#{race} / Flip / Tuner / Effect]"
    end,
    'Tuner Monster' => ->(race) { "[#{race} / Tuner / Effect]" },
    'Toon Monster' => ->(race) { "[#{race} / Toon / Effect]" },
    'Gemini Monster' => ->(race) { "[#{race} / Gemini / Effect]" },
    'Spirit Monster' => ->(race) { "[#{race} / Spirit / Effect]" },
    'Union Effect Monster' => ->(race) { "[#{race} / Union / Effect]" },
    'Union Tuner Effect Monster' => ->(race) do
      "[#{race} / Union / Tuner / Effect]"
    end,
    'Ritual Monster' => ->(race) { "[#{race} / Ritual]" },
    'Ritual Effect Monster' => ->(race) { "[#{race} / Ritual / Effect]" },
    'Fusion Monster' => ->(race) { "[#{race} / Fusion / Effect]" },
    'Synchro Monster' => ->(race) { "[#{race} / Synchro / Effect]" },
    'Synchro Pendulum Effect Monster' => ->(race) do
      "[#{race} / Synchro / Pendulum / Effect]"
    end,
    'Synchro Tuner Monster' => ->(race) do
      "[#{race} / Synchro / Tuner / Effect]"
    end,
    'XYZ Monster' => ->(race) { "[#{race} / XYZ / Effect]" },
    'XYZ Pendulum Effect Monster' => ->(race) do
      "[#{race} / XYZ / Pendulum / Effect]"
    end,
    'Pendulum Effect Monster' => ->(race) { "[#{race} / Pendulum / Effect]" },
    'Pendulum Flip Effect Monster' => ->(race) do
      "[#{race} / Pendulum / Flip / Effect]"
    end,
    'Pendulum Normal Monster' => ->(race) { "[#{race} / Pendulum]" },
    'Pendulum Tuner Effect Monster' => ->(race) do
      "[#{race} / Pendulum / Tuner / Effect]"
    end,
    'Pendulum Effect Fusion Monster' => ->(race) do
      "[#{race} / Pendulum / Effect / Fusion]"
    end,
    'Link Monster' => ->(race) { "[#{race} / Link / Effect]" }
  }.freeze

  def self.random_card
    card = Ygoprodeck::Card.random

    return { message: 'No card found.' } if card.nil? || card['id'].nil?

    id = card['id']
    type = card['type']
    image_url = Ygoprodeck::Image_small.is(id)

    message =
      if MONSTER_TYPES.include?(type)
        format_monster_card(card)
      elsif NON_MONSTER_TYPES.include?(type)
        format_non_monster_card(card)
      else
        "*#{card['name']}* has an unrecognized type: #{type}"
      end

    { message: message, image: image_url }
  end

  private

  def self.format_monster_card(card)
    name = card['name'].to_s
    type = card['type'].to_s
    attribute = card['attribute'].to_s
    level = card['level'].to_s
    race = card['race'].to_s
    desc = card['desc'].to_s
    atk = card['atk'].to_s
    defe = card['def'].to_s
    ban_ocg = card.dig('banlist_info', 'ban_ocg') || 'Unlimited'
    ban_tcg = card.dig('banlist_info', 'ban_tcg') || 'Unlimited'

    about = TYPE_DESCRIPTIONS[type]&.call(race) || ''

    <<~TEXT.strip
      *#{name}*
      OCG: #{ban_ocg} | TCG: #{ban_tcg}
      *Type:* #{type}
      *Attribute:* #{attribute}
      *Level:* #{level}
      *ATK/DEF:* #{atk}/#{defe}
      *#{about}*
      #{desc}
    TEXT
  end

  def self.format_non_monster_card(card)
    name = card['name'].to_s
    type = card['type'].to_s
    race = card['race'].to_s
    desc = card['desc'].to_s
    ban_ocg = card.dig('banlist_info', 'ban_ocg') || 'Unlimited'
    ban_tcg = card.dig('banlist_info', 'ban_tcg') || 'Unlimited'

    <<~TEXT.strip
      *#{name}*
      OCG: #{ban_ocg} | TCG: #{ban_tcg}
      *Type:* #{type}
      *Race:* #{race}
      *Effect* 
      #{desc}
    TEXT
  end
end
