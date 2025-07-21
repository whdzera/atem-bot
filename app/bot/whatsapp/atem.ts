import { BaileysClass } from '../../../lib/baileys.js';
import fetch from 'node-fetch';
import dotenv from 'dotenv';
import path from 'path';

import { handleInfo, handleHelp, handlePing } from './commands/General';
import { fetchRandomCard } from './commands/Random';
import { fetchCardImage } from './commands/Card';
import { fetchCardData } from './commands/SearchCard';
import { listCards } from './commands/ListCard';

// initialize Atem bot
dotenv.config({ path: path.resolve(__dirname, '../../../config/.env') });
const atem = new BaileysClass({});
const GEMINI_API_KEY = process.env.gemini_api_key!;
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;
const formatPattern = /:: *(.*?) *::/;

// Function to log messages with a timestamp
function logWithTime(level: 'INFO' | 'ERROR' | 'WARN', ...message: any[]) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

// Function to send text messages with logging
async function sendTextLog(to: string, message: string) {
  logWithTime('INFO', `Sending text to ${to}:`, message.replace(/\n/g, ' | '));
  await atem.sendText(to, message);
}

// Function to send media with a caption
async function sendMediaLog(to: string, mediaUrl: string, caption: string) {
  logWithTime('INFO', `Sending media to ${to}: ${mediaUrl}`);
  logWithTime('INFO', `With caption:`, caption.replace(/\n/g, ' | '));
  await atem.sendMedia(to, mediaUrl, caption);
}

// Handler for Gemini AI fallback
async function handleGeminiFallback(query: string, to: string) {
  const prompt = `cari kartu yugioh ${query}, jika tidak ada tolong perbaiki nama nya agar mendekati nama kartu yugioh yang ada di database`;

  try {
    const res = await fetch(GEMINI_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }]
      })
    });

    if (res.ok) {
      const data = await res.json();
      const botResponse = data?.candidates?.[0]?.content?.parts?.[0]?.text || 'Maaf, saya tidak bisa memproses permintaan Anda.';
      const matchAnswer = botResponse.match(/^(.+?\n\n?){1,4}/m)?.[0] || botResponse;
      await sendTextLog(to, `*Card Not Found*\n\n[AI Help]\n${matchAnswer}`);
    } else {
      await sendTextLog(to, 'Card Not Found.\n\n[AI Help] Gemini API error.');
    }
  } catch (error) {
    console.error('Gemini AI Error:', error);
    await sendTextLog(to, 'Card Not Found.\n\n[AI Help] Internal error when contacting Gemini.');
  }
}

// Event listeners for Atem bot
atem.on('auth_failure', error => logWithTime('ERROR', "Auth failed:", error));
atem.on('qr', qr => logWithTime('INFO', "NEW QR CODE:", qr));
atem.on('ready', () => logWithTime('INFO', 'READY BOT'));
atem.on('message', async (message) => {
  const isGroup = message.from.endsWith('@g.us');
  const body = message.body.toLowerCase();

  if (body === ':info') {
    await handleInfo(sendTextLog, message.from);
  }

  else if (body === ':help') {
    await handleHelp(sendTextLog, message.from);
  }

  else if (body === ':ping') {
    await handlePing(sendTextLog, message.from);
  }

  else if (body === ':random') {
    const { info, imageUrl } = await fetchRandomCard();

    if (imageUrl) {
      await sendMediaLog(message.from, imageUrl, info);
    } else {
      await sendTextLog(message.from, info);
    }
  }

  else if (body.startsWith(':list')) {
    const match = body.match(/^:list\s+(.+)$/i);
    if (!match) {
      await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:list *kata kunci*`');
      return;
    }

    const searchTerm = match[1].trim();
    const result = await listCards(searchTerm);
    await sendTextLog(message.from, result);
  }

  else if (body.startsWith(':card')) {
    const match = body.match(/^:card\s+(.+)$/i);
    if (!match) {
      await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:card *nama kartu*`');
      return;
    }

    const cardName = match[1].trim();
    const { imageUrl } = await fetchCardImage(cardName);

    if (imageUrl) {
      await sendMediaLog(message.from, imageUrl, '');
    } else {
      await sendTextLog(message.from, `Gambar kartu "${cardName}" tidak ditemukan.`);
    }
  }

  else if (body.startsWith(':search')) {
    const match = body.match(/^:search\s+(.+)$/i);
    if (!match) {
      await sendTextLog(message.from, 'Format salah. Gunakan seperti ini: `:search *nama kartu*`');
      return;
    }

    const query = match[1].trim();
    const result = await fetchCardData(query);

    if (result.imageUrl) {
      await sendMediaLog(message.from, result.imageUrl, result.info);
    } else {
      await handleGeminiFallback(query, message.from);
    }
  }

  else if (isGroup) {
    const match = message.body.match(formatPattern);
    if (match) {
      const extracted = match[1];
      const result = await fetchCardData(extracted);

      if (result.imageUrl) {
        await sendMediaLog(message.from, result.imageUrl, result.info);
      } else {
        await handleGeminiFallback(extracted, message.from);
      }
    }
  }
});
