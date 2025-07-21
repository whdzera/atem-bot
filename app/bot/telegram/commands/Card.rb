class Card
  def self.message(from)
    matching = Ygoprodeck::Match.is(from)
    card = Ygoprodeck::Fname.is(matching)
    id = card['id']

    return { error: "*#{from}* not found." } if card.nil? || card['id'].nil?

    image = Ygoprodeck::Image.is(id)

    { image: image, success: true }
  end
end
