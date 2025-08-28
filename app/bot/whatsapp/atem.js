import {
  makeWASocket,
  fetchLatestBaileysVersion,
  DisconnectReason,
  useMultiFileAuthState,
  makeCacheableSignalKeyStore,
  Browsers,
} from "@whiskeysockets/baileys";
import Pino from "pino";
import fs from "fs";
import chalk from "chalk";
import qrcode from "qrcode-terminal";
import NodeCache from "@cacheable/node-cache";
import fetch from "node-fetch";
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import { dirname } from "path";

import { handleInfo, handleHelp, handlePing } from "./commands/General.js";
import { listCards } from "./commands/ListCard.js";
import { fetchRandomCard } from "./commands/RandomCard.js";
import { fetchCardData } from "./commands/SearchCard.js";
import { fetchCardImage } from "./commands/Card.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// initialize Atem bot
dotenv.config({ path: path.resolve(__dirname, "../../../config/.env") });
const GEMINI_API_KEY = process.env.gemini_api_key;
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`;
const formatPattern = /:: *(.*?) *::/;

const logger = Pino({ level: "silent" });
const groupCache = new NodeCache();

const color = (text, colorName) => {
  return !colorName ? chalk.green(text) : chalk.keyword(colorName)(text);
};

// Function to log messages with a timestamp
function logWithTime(level, ...message) {
  const time = new Date().toISOString();
  console.log(`[${level}] [${time}]`, ...message);
}

// Function to send text messages with logging
async function sendTextLog(to, message) {
  logWithTime("INFO", `Sending text to ${to}:`, message.replace(/\n/g, " | "));
  await sock.sendMessage(to, { text: message });
}

// Function to send media with a caption
async function sendMediaLog(to, mediaUrl, caption) {
  logWithTime("INFO", `Sending media to ${to}: ${mediaUrl}`);
  logWithTime("INFO", `With caption:`, caption.replace(/\n/g, " | "));
  await sock.sendMessage(to, {
    image: { url: mediaUrl },
    caption: caption,
  });
}

// Handler for Gemini AI fallback
async function handleGeminiFallback(query, to) {
  const prompt = `cari kartu yugioh ${query}, jika tidak ada tolong perbaiki nama nya agar mendekati nama kartu yugioh yang ada di database`;

  try {
    const res = await fetch(GEMINI_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    });

    if (res.ok) {
      const data = await res.json();
      const botResponse =
        data?.candidates?.[0]?.content?.parts?.[0]?.text ||
        "Maaf, saya tidak bisa memproses permintaan Anda.";
      const matchAnswer =
        botResponse.match(/^(.+?\n\n?){1,4}/m)?.[0] || botResponse;
      await sendTextLog(to, `*Card Not Found*\n\n[AI Help]\n${matchAnswer}`);
    } else {
      await sendTextLog(to, "Card Not Found.\n\n[AI Help] Gemini API error.");
    }
  } catch (error) {
    console.error("Gemini AI Error:", error);
    await sendTextLog(
      to,
      "Card Not Found.\n\n[AI Help] Internal error when contacting Gemini."
    );
  }
}

async function connectToWhatsApp() {
  const { state, saveCreds } = await useMultiFileAuthState("./sessions");
  const { version } = await fetchLatestBaileysVersion();

  const sock = makeWASocket({
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, logger),
    },
    version,
    logger,
    browser: Browsers.macOS("Chrome"),
    retryRequestDelayMs: 300,
    maxMsgRetryCount: 10,
    markOnlineOnConnect: true,
    generateHighQualityLinkPreview: true,
    cachedGroupMetadata: async (jid) => groupCache.get(jid),
  });

  // Function to send text messages with logging
  const sendTextLog = async (to, message) => {
    logWithTime(
      "INFO",
      `Sending text to ${to}:`,
      message.replace(/\n/g, " | ")
    );
    await sock.sendMessage(to, { text: message });
  };

  // Function to send media with a caption
  const sendMediaLog = async (to, mediaUrl, caption) => {
    logWithTime("INFO", `Sending media to ${to}: ${mediaUrl}`);
    logWithTime("INFO", `With caption:`, caption.replace(/\n/g, " | "));
    await sock.sendMessage(to, {
      image: { url: mediaUrl },
      caption: caption,
    });
  };

  // Handler for Gemini AI fallback
  const handleGeminiFallback = async (query, to) => {
    const prompt = `cari kartu yugioh ${query}, jika tidak ada tolong perbaiki nama nya agar mendekati nama kartu yugioh yang ada di database`;

    try {
      const res = await fetch(GEMINI_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      });

      if (res.ok) {
        const data = await res.json();
        const botResponse =
          data?.candidates?.[0]?.content?.parts?.[0]?.text ||
          "Maaf, saya tidak bisa memproses permintaan Anda.";
        const matchAnswer =
          botResponse.match(/^(.+?\n\n?){1,4}/m)?.[0] || botResponse;
        await sendTextLog(to, `*Card Not Found*\n\n[AI Help]\n${matchAnswer}`);
      } else {
        await sendTextLog(to, "Card Not Found.\n\n[AI Help] Gemini API error.");
      }
    } catch (error) {
      console.error("Gemini AI Error:", error);
      await sendTextLog(
        to,
        "Card Not Found.\n\n[AI Help] Internal error when contacting Gemini."
      );
    }
  };

  sock.ev.process(async (events) => {
    // Handle connection updates
    if (events["connection.update"]) {
      const update = events["connection.update"];
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        console.log("\n=== WhatsApp Web QR Code ===");
        qrcode.generate(qr, { small: true });
        logWithTime("INFO", "NEW QR CODE:", qr);
      }

      if (connection === "close") {
        const statusCode = lastDisconnect?.error?.output?.statusCode;
        const reason =
          Object.entries(DisconnectReason).find(
            (i) => i[1] === statusCode
          )?.[0] || "unknown";

        console.log(
          color(`Connection closed. Reason: ${reason} (${statusCode})`, "red")
        );

        if (reason === "loggedOut" || statusCode === 403) {
          fs.rmSync("./sessions", { recursive: true, force: true });
        } else {
          connectToWhatsApp();
        }
      }

      if (connection === "open") {
        logWithTime("INFO", "READY BOT");
      }
    }

    // Handle credentials update
    if (events["creds.update"]) {
      await saveCreds();
    }

    // Handle messages
    const upsert = events["messages.upsert"];
    if (upsert) {
      const message = upsert.messages[0];
      if (!message?.message) return;

      const from = message.key.remoteJid;
      const isGroup = from?.endsWith("@g.us") || false;
      const body =
        message.message?.conversation ||
        message.message?.extendedTextMessage?.text ||
        "";

      // Handle commands
      if (body === ":info") {
        await handleInfo(sendTextLog, from);
      } else if (body === ":help") {
        await handleHelp(sendTextLog, from);
      } else if (body === ":ping") {
        await handlePing(sendTextLog, from);
      } else if (body === ":random") {
        const { info, imageUrl } = await fetchRandomCard();
        if (imageUrl) {
          await sendMediaLog(from, imageUrl, info);
        } else {
          await sendTextLog(from, info);
        }
      } else if (body.startsWith(":list")) {
        const match = body.match(/^:list\s+(.+)$/i);
        if (!match) {
          await sendTextLog(
            from,
            "Format salah. Gunakan seperti ini: `:list *kata kunci*`"
          );
          return;
        }
        const searchTerm = match[1].trim();
        const result = await listCards(searchTerm);
        await sendTextLog(from, result);
      } else if (body.startsWith(":card")) {
        const match = body.match(/^:card\s+(.+)$/i);
        if (!match) {
          await sendTextLog(
            from,
            "Format salah. Gunakan seperti ini: `:card *nama kartu*`"
          );
          return;
        }
        const cardName = match[1].trim();
        const { imageUrl } = await fetchCardImage(cardName);

        if (imageUrl) {
          await sendMediaLog(from, imageUrl, "");
        } else {
          await sendTextLog(
            from,
            `Gambar kartu "${cardName}" tidak ditemukan.`
          );
        }
      } else if (body.startsWith(":search")) {
        const match = body.match(/^:search\s+(.+)$/i);
        if (!match) {
          await sendTextLog(
            from,
            "Format salah. Gunakan seperti ini: `:search *nama kartu*`"
          );
          return;
        }
        const query = match[1].trim();
        const result = await fetchCardData(query);

        if (result.imageUrl) {
          await sendMediaLog(from, result.imageUrl, result.info);
        } else {
          await handleGeminiFallback(query, from);
        }
      } else if (isGroup) {
        // Fix: Use the same body extraction as above
        const match = body.match(formatPattern);
        if (match) {
          const extracted = match[1];
          const result = await fetchCardData(extracted);

          if (result.imageUrl) {
            await sendMediaLog(from, result.imageUrl, result.info);
          } else {
            await handleGeminiFallback(extracted, from);
          }
        }
      }
    }
  });

  return sock;
}

// Start the connection
connectToWhatsApp();
