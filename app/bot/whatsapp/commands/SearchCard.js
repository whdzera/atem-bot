import fetch from 'node-fetch';
import Fuse from 'fuse.js';
import { loadJsonFile } from '../utils/jsonLoader.js';

const allCardNames = loadJsonFile('app/data/ygo.json');

function logWithTime(level, ...message) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

const normalizedCards = allCardNames.map((name) => normalize(name));

const fuse = new Fuse(normalizedCards, {
  includeScore: true,
  threshold: 0.4,
  distance: 100
});

function normalize(text) {
  return text
    .toLowerCase()
    .replace(/[-.,'"]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export async function fetchCardData(cardName) {
  try {
    const normalizedQuery = normalize(cardName);
    const substringIndex = normalizedCards.findIndex((n) =>
      n.includes(normalizedQuery)
    );
    let bestMatch;

    if (substringIndex !== -1) {
      bestMatch = allCardNames[substringIndex];
    } else {
      const results = fuse.search(normalizedQuery);
      bestMatch =
        results.length > 0 ? allCardNames[results[0].refIndex] : cardName;
    }

    const encodedName = encodeURIComponent(bestMatch);
    const response = await fetch(
      `https://db.ygoprodeck.com/api/v7/cardinfo.php?fname=${encodedName}`
    );
    const data = await response.json();

    if (data.error) {
      return { info: `Card not found: ${cardName}` };
    }

    const card = data.data[0];
    let cardInfo = `${card.name}\n`;
    
    // OCG/TCG Status
    cardInfo += `OCG: ${card.banlist_info?.ban_ocg ?? "Unlimited"}\n`;
    cardInfo += `TCG: ${card.banlist_info?.ban_tcg ?? "Unlimited"}\n`;
    
    // Basic Info
    cardInfo += `Type: ${card.type}\n`;
    if (card.attribute) cardInfo += `Attribute: ${card.attribute}\n`;
    if (card.archetype) cardInfo += `Archetype: ${card.archetype}\n`;
    if (card.level) cardInfo += `Level/Rank: ${card.level}\n`;
    if (card.race) cardInfo += `Race: ${card.race}\n`;
    
    // Stats
    if (card.atk !== undefined) cardInfo += `ATK: ${card.atk}`;
    if (card.def !== undefined) cardInfo += ` | DEF: ${card.def}\n`;
    
    // Card Text
    cardInfo += `\nCard Text\n${card.desc}\n`;

    const imageUrl = card.card_images?.[0]?.image_url_cropped;
    return { info: cardInfo, imageUrl };

  } catch (error) {
    console.error('Error fetching card data:', error);
    return { info: 'Error fetching card data. Please try again later.' };
  }
}
