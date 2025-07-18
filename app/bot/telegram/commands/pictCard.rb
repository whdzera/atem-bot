class Pict
  def self.link(from)
    matching = Ygoprodeck::Match.is(from)
    card = Ygoprodeck::Fname.is(matching)

    return 'https://i.imgur.com/lPSo3Tt.jpg' if card.nil? || card['id'].nil?

    Ygoprodeck::Image_small.is(card['id'])
  end
end
