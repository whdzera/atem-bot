class Card
  def self.message(from)
    matching = Ygoprodeck::Match.is(from)
    card = Ygoprodeck::Fname.is(matching)

    return "*#{from}* tidak ditemukan." if card.nil? || card['id'].nil?

    type = card['type']
    return format_monster_card(card) if MONSTER_TYPES.include?(type)
    return format_non_monster_card(card) if NON_MONSTER_TYPES.include?(type)

    "*#{card['name']}* memiliki tipe yang tidak dikenali: #{type}"
  end
end
