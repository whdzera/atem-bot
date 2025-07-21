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

export async function fetchCardImage(cardName: string): Promise<{ imageUrl?: string }> {
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

    if (data.error || !data.data || data.data.length === 0) {
      return {};
    }

    const card = data.data[0];
    const imageUrl = card.card_images?.[0]?.image_url || card.card_images?.[0]?.image_url;

    return { imageUrl };

  } catch (error) {
    logWithTime('ERROR', 'Error fetching card image:', error);
    return {};
  }
}
