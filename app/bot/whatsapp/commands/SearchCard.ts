import fetch from 'node-fetch';
import Fuse from 'fuse.js';
import allCardNames from '../../../data/ygo.json';

function logWithTime(level: 'INFO' | 'ERROR' | 'WARN', ...message: any[]) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

const normalizedCards = allCardNames.map(name => normalize(name));

const fuse = new Fuse(normalizedCards, {
  includeScore: true,
  threshold: 0.4,
  distance: 100,
});

function normalize(text: string): string {
  return text.toLowerCase()
    .replace(/[-.,'"]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export async function fetchCardData(cardName: string): Promise<{ info: string, imageUrl?: string }> {
  try {
    const normalizedQuery = normalize(cardName);

    const substringIndex = normalizedCards.findIndex(n => n.includes(normalizedQuery));
    let bestMatch: string;

    if (substringIndex !== -1) {
      bestMatch = allCardNames[substringIndex];
    } else {
      const results = fuse.search(normalizedQuery);
      bestMatch = results.length > 0 ? allCardNames[results[0].refIndex] : cardName;
    }

    const encodedName = encodeURIComponent(bestMatch);
    const response = await fetch(`https://db.ygoprodeck.com/api/v7/cardinfo.php?fname=${encodedName}`);
    const data: any = await response.json();

    if (data.error) {
      return { info: `Card not found: ${cardName}` };
    }

    const card = data.data[0];
    let cardInfo = `*${card.name}*\n`;
    cardInfo += `*_OCG:_* ${card.banlist_info?.ban_ocg ?? "Unlimited"}\n`;
    cardInfo += `*_TCG:_* ${card.banlist_info?.ban_tcg ?? "Unlimited"}\n`;
    cardInfo += `*_Type:_* ${card.type}\n`;
    if (card.attribute) cardInfo += `*_Attribute:_* ${card.attribute}\n`;
    if (card.archetype) cardInfo += `*_Archetype:_* ${card.archetype}\n`;
    if (card.level) cardInfo += `*_Level/Rank:_* ${card.level}\n`;
    if (card.race) cardInfo += `*_Race:_* ${card.race}\n`;
    if (card.atk !== undefined) cardInfo += `*_ATK:_* ${card.atk} | `;
    if (card.def !== undefined) cardInfo += `*_DEF:_* ${card.def}\n`;
    if (card.linkval !== undefined) cardInfo += `*_Linkval:_* ${card.linkval} [${card.linkmarkers}]\n`;
    cardInfo += `\n*_Card Text_*\n${card.desc}\n`;

    const imageUrl = card.card_images?.[0]?.image_url_cropped;
    return { info: cardInfo, imageUrl };

  } catch (error) {
    logWithTime('ERROR', 'Error fetching card data:', error);
    return { info: 'Error fetching card data. Please try again later.' };
  }
}
