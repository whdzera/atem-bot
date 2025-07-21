import fetch from 'node-fetch';

export async function handleInfo(send: (to: string, message: string) => Promise<void>, to: string) {
  const message = `*Atem* (version 1.1.0)
Whatsapp Bot for search yugioh card

*Developer* 
- 089612893953 (whdzera)

\`:help\` for usage 

*Donation*
https://saweria.co/whdzera`;
  await send(to, message);
}

export async function handleHelp(send: (to: string, message: string) => Promise<void>, to: string) {
  const message = `*Usage*
- \`:info\` Information about bot 
- \`:ping\` information Latency Server
- \`:random\` random card
- \`:list blue-eyes\` list cards
- \`:card harpie lady\` image card
- \`:search dark magician\` search card 
- \`::dark magician::\` search card dynamic`;
  await send(to, message);
}

export async function handlePing(send: (to: string, message: string) => Promise<void>, to: string) {
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
  const messageStatus = `*Pong!*
- Server latency: ${serverLatency - 40}ms.
- API latency: ${apiLatency}`;
  await send(to, messageStatus);
}
