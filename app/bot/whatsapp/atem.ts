import { BaileysClass } from '../../../lib/baileys.js';
import fetch from 'node-fetch';
import dotenv from 'dotenv';
import Fuse from 'fuse.js';
import path from 'path';
import allCardNames from '../../data/ygo.json'; 

dotenv.config({ path: path.resolve(__dirname, '../../../config/.env') });

const botBaileys = new BaileysClass({});

function logWithTime(level: 'INFO' | 'ERROR' | 'WARN', ...message: any[]) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

async function sendTextLog(to: string, message: string) {
  logWithTime('INFO', `Sending text to ${to}:`, message.replace(/\n/g, ' | '));
  await botBaileys.sendText(to, message);
}

async function sendMediaLog(to: string, mediaUrl: string, caption: string) {
  logWithTime('INFO', `Sending media to ${to}: ${mediaUrl}`);
  logWithTime('INFO', `With caption:`, caption.replace(/\n/g, ' | '));
  await botBaileys.sendMedia(to, mediaUrl, caption);
}

botBaileys.on('auth_failure', async (error) => logWithTime('ERROR', "Auth failed:", error));
botBaileys.on('qr', (qr) => logWithTime('INFO', "NEW QR CODE:", qr));
botBaileys.on('ready', async () => logWithTime('INFO', 'READY BOT'));

const formatPattern = /:: *(.*?) *::/;
const GEMINI_API_KEY = process.env.gemini_api_key!;
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;

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
      if (results.length > 0) {
        bestMatch = allCardNames[results[0].refIndex];
      } else {
        bestMatch = cardName;
      }
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

async function listCards(searchTerm: string): Promise<string> {
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
        logWithTime('ERROR', 'Error listing cards:', error);
        return 'Error searching for cards. Please try again later.';
    }
}

botBaileys.on('message', async (message) => {
    const isGroup = message.from.endsWith('@g.us');
    const match = message.body.match(formatPattern);

    // information bot
    if (message.body.toLowerCase() === ':atem') {
        await sendTextLog(message.from, '*Atem* (version 1.1.0)\nWhatsapp Bot for search yugioh card\n\n*Developer* \n- 089612893953 (whdzera)\n\n`:help` for usage \n\n*Donation*\nhttps://saweria.co/whdzera');
    }

    // helping and usage
    if (message.body.toLowerCase() === ':help') {
        await sendTextLog(message.from, '*Usage*\n- `:atem` Information about bot \n- `:status` information Latency Server\n- `:ls blue-eyes` list cards \n- `:src dark magician` search card \n- `::dark magician::` search card dynamic');
    }

    // Status Latency API and Server
    if (message.body.toLowerCase() === ':status') {
      const start = Date.now();

      let apiLatency: string;
      try {
        const res = await fetch('https://db.ygoprodeck.com/api/v7/cardinfo.php?name=dark%20magician');
        const json = await res.json();
        const end = Date.now();
        apiLatency = json?.data?.[0]?.id ? `${end - start}ms.` : 'ERROR';
      } catch (err) {
        apiLatency = 'ERROR';
      }

      const serverLatency = Date.now() - start;

      const messageStatus = `*Status*\n- Server latency: ${serverLatency - 40}ms.\n- API latency: ${apiLatency}`;
      await sendTextLog(message.from, messageStatus);
    }

    // List cards
    if (message.body.toLowerCase().startsWith(':ls')) {
        const match = message.body.match(/^:ls\s+(.+)$/i);

        if (!match) {
            await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:ls *kata kunci*`');
            return;
        }

        const searchTerm = match[1].trim();
        
        const result = await listCards(searchTerm);
        await sendTextLog(message.from, result);
    }

    // Search card Private
    if (message.body.toLowerCase().startsWith(':src')) {
        const match = message.body.match(/^:src\s+(.+)$/i);

    if (!match) {
        await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:src *nama kartu*`');
        return;
    }

    const text = match[1].trim();

    const result = await fetchCardData(text);
    if (result.imageUrl) {
        await sendMediaLog(message.from, result.imageUrl, result.info);
    } else {
        const prompt = `cari kartu yugioh ${text}, jika tidak ada tolong perbaiki nama nya agar mendekati nama kartu yugioh yang ada di database`;

        try {
        const geminiResponse = await fetch(GEMINI_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
            })
        });

        if (geminiResponse.ok) {
            const data = await geminiResponse.json();
            const botResponse = data?.candidates?.[0]?.content?.parts?.[0]?.text || 'Maaf, saya tidak bisa memproses permintaan Anda.';
            const matchAnswer = botResponse.match(/^(.+?\n\n?){1,4}/m)?.[0] || botResponse;

            await sendTextLog(message.from, `*Card Not Found*\n\n[AI Help]\n${matchAnswer}`);
        } else {
            await sendTextLog(message.from, 'Card Not Found.\n\n[AI Help] Gemini API error.');
        }
        } catch (error) {
        console.error('Gemini AI Error:', error);
        await sendTextLog(message.from, 'Card Not Found.\n\n[AI Help] Internal error when contacting Gemini.');
        }
    }
    }

    // Search yugioh card in group
    if (isGroup && match) {
        const extractedText = match[1];
        const result = await fetchCardData(extractedText);
        if (result.imageUrl) {
            await sendMediaLog(message.from, result.imageUrl, result.info);
        }
        else {
    const prompt = `cari kartu yugioh ${extractedText}, jika tidak ada tolong perbaiki nama nya agar mendekati nama kartu yugioh yang ada di database`;

    try {
        const geminiResponse = await fetch(GEMINI_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }]
        })
        });

        if (geminiResponse.ok) {
        const data = await geminiResponse.json();
        const botResponse = data?.candidates?.[0]?.content?.parts?.[0]?.text || 'Maaf, saya tidak bisa memproses permintaan Anda.';
        
        const matchAnswer = botResponse.match(/^(.+?\n\n?){1,4}/m)?.[0] || botResponse;

        await sendTextLog(message.from, `*Card Not Found*\n\n[AI Help]\n${matchAnswer}`);
        } else {
        await sendTextLog(message.from, 'Card Not Found.\n\n[AI Help] Gemini API error.');
        }
    } catch (error) {
        console.error('Gemini AI Error:', error);
        await sendTextLog(message.from, 'Card Not Found.\n\n[AI Help] Internal error when contacting Gemini.');
    }
    }

    }
    
});