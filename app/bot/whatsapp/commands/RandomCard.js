import fetch from 'node-fetch';

function logWithTime(level, ...message) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

export async function fetchRandomCard() {
  try {
    const response = await fetch(
      'https://db.ygoprodeck.com/api/v7/randomcard.php'
    );
    const data = await response.json();

    if (data.error || !data.data || data.data.length === 0) {
      return { info: 'Random card not found. Silakan coba lagi.' };
    }

    const card = data.data[0];
    let cardInfo = `*${card.name}*\n`;
    cardInfo += `*_OCG:_* ${card.banlist_info?.ban_ocg ?? 'Unlimited'}\n`;
    cardInfo += `*_TCG:_* ${card.banlist_info?.ban_tcg ?? 'Unlimited'}\n`;
    cardInfo += `*_Type:_* ${card.type}\n`;
    if (card.attribute) cardInfo += `*_Attribute:_* ${card.attribute}\n`;
    if (card.archetype) cardInfo += `*_Archetype:_* ${card.archetype}\n`;
    if (card.level) cardInfo += `*_Level/Rank:_* ${card.level}\n`;
    if (card.race) cardInfo += `*_Race:_* ${card.race}\n`;
    if (card.atk !== undefined) cardInfo += `*_ATK:_* ${card.atk} | `;
    if (card.def !== undefined) cardInfo += `*_DEF:_* ${card.def}\n`;
    if (card.linkval !== undefined)
      cardInfo += `*_Linkval:_* ${card.linkval} [${card.linkmarkers}]\n`;
    cardInfo += `\n*_Card Text_*\n${card.desc}\n`;

    const imageUrl = card.card_images?.[0]?.image_url_cropped;
    return { info: cardInfo, imageUrl };
  } catch (error) {
    logWithTime('ERROR', 'Error fetching random card:', error);
    return {
      info: 'Terjadi kesalahan saat mengambil kartu random. Silakan coba lagi nanti.'
    };
  }
}
