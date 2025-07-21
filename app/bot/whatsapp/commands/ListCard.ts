import fetch from 'node-fetch';

export async function listCards(searchTerm: string): Promise<string> {
  try {
    const encodedTerm = encodeURIComponent(searchTerm);
    const response = await fetch(`https://db.ygoprodeck.com/api/v7/cardinfo.php?fname=${encodedTerm}`);
    const data: any = await response.json();

    if (data.error) {
      return `No cards found matching "${searchTerm}"`;
    }

    data.data.sort((a: any, b: any) => a.name.localeCompare(b.name));

    const cards = data.data.slice(0, 20);
    const cardCount = data.data.length;
    let message = `${cardCount} card${cardCount !== 1 ? 's' : ''} found`;

    if (cardCount > 20) {
      message += ` (showing first 20)`;
    }

    message += `:\n`;

    cards.forEach((card: any, index: number) => {
      message += `* ${card.name}\n`;
    });

    if (cardCount > 20) {
      message += `\nUse more specific search terms to narrow results.`;
    }

    return message;
  } catch (error) {
    console.error('[ERROR] listCards:', error);
    return 'Error searching for cards. Please try again later.';
  }
}
