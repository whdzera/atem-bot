class Card
  def self.message(from)
    # Cari kartu berdasarkan nama/keyword
    matching = Ygoprodeck::Match.is(from)
    card = Ygoprodeck::Fname.is(matching)
    id = card['id']

    # Jika kartu tidak ditemukan
    if card.nil? || card['id'].nil?
      return { error: "*#{from}* tidak ditemukan." }
    end

    # Dapatkan gambar kartu
    image = Ygoprodeck::Image.is(id)

    # Return hash dengan gambar dan info dasar kartu
    { image: image, success: true }
  end
end
