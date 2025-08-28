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

export async function fetchCardImage(cardName) {
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

    if (data.error || !data.data || data.data.length === 0) {
      return {};
    }

    const card = data.data[0];
    const imageUrl =
      card.card_images?.[0]?.image_url || card.card_images?.[0]?.image_url;

    return { imageUrl };
  } catch (error) {
    logWithTime('ERROR', 'Error fetching card image:', error);
    return {};
  }
}
