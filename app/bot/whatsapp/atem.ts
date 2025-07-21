import { BaileysClass } from '../../../lib/baileys.js';
import fetch from 'node-fetch';
import dotenv from 'dotenv';
import path from 'path';

import { fetchCardData } from './commands/SearchCard';
import { listCards } from './commands/ListCard';

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

botBaileys.on('message', async (message) => {
    const isGroup = message.from.endsWith('@g.us');
    const match = message.body.match(formatPattern);

    // information bot
    if (message.body.toLowerCase() === ':info') {
        await sendTextLog(message.from, '*Atem* (version 1.1.0)\nWhatsapp Bot for search yugioh card\n\n*Developer* \n- 089612893953 (whdzera)\n\n`:help` for usage \n\n*Donation*\nhttps://saweria.co/whdzera');
    }

    // helping and usage
    if (message.body.toLowerCase() === ':help') {
        await sendTextLog(message.from, '*Usage*\n- `:info` Information about bot \n- `:ping` information Latency Server\n- `:list blue-eyes` list cards \n- `:search dark magician` search card \n- `::dark magician::` search card dynamic');
    }

    // Status Latency API and Server
    if (message.body.toLowerCase() === ':ping') {
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

      const messageStatus = `*Pong!*\n- Server latency: ${serverLatency - 40}ms.\n- API latency: ${apiLatency}`;
      await sendTextLog(message.from, messageStatus);
    }

    // List cards
    if (message.body.toLowerCase().startsWith(':list')) {
        const match = message.body.match(/^:list\s+(.+)$/i);

        if (!match) {
            await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:list *kata kunci*`');
            return;
        }

        const searchTerm = match[1].trim();
        
        const result = await listCards(searchTerm);
        await sendTextLog(message.from, result);
    }

    // Search card Private
    if (message.body.toLowerCase().startsWith(':search')) {
        const match = message.body.match(/^:search\s+(.+)$/i);

    if (!match) {
        await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:search *nama kartu*`');
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