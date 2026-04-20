const OG_IMAGE_B64 = "__OG_IMAGE_B64__";

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>planyr — coming soon</title>
  <meta name="description" content="A bullet-journal-inspired weekly planner. Coming soon." />

  <!-- Open Graph / LinkedIn / Facebook -->
  <meta property="og:type" content="website" />
  <meta property="og:url" content="https://planyr.day" />
  <meta property="og:title" content="planyr — a weekly planner, the bullet-journal way" />
  <meta property="og:description" content="A matrix-based weekly planner inspired by bullet journals. Coming soon to iOS and Android." />
  <meta property="og:image" content="https://planyr.day/og-image.png" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="627" />
  <meta property="og:image:alt" content="planyr — a weekly planner, the bullet-journal way. Coming soon." />
  <meta property="og:site_name" content="planyr" />

  <!-- Twitter -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="planyr — a weekly planner, the bullet-journal way" />
  <meta name="twitter:description" content="A matrix-based weekly planner inspired by bullet journals. Coming soon to iOS and Android." />
  <meta name="twitter:image" content="https://planyr.day/og-image.png" />

  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Patrick+Hand&display=swap" rel="stylesheet" />
  <style>
    :root {
      --paper: #F5F0E8;
      --paper-dim: #EDE7DA;
      --ink: #2C2520;
      --ink-soft: #6B6560;
      --accent: #5B8A72;
      --dot: #D5CCBC;
    }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      padding: 0;
      font-family: 'Patrick Hand', system-ui, -apple-system, sans-serif;
      background-color: var(--paper);
      color: var(--ink);
      min-height: 100vh;
    }
    body {
      background-image: radial-gradient(var(--dot) 1px, transparent 1px);
      background-size: 24px 24px;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
    }
    .card {
      max-width: 560px;
      width: 100%;
      padding: 48px 40px;
      background: var(--paper);
      border: 1px solid rgba(44, 37, 32, 0.12);
      border-radius: 12px;
      box-shadow: 0 20px 50px rgba(44, 37, 32, 0.08);
      text-align: center;
    }
    h1 {
      font-size: 64px;
      margin: 0 0 8px;
      letter-spacing: -1px;
    }
    .tagline {
      font-size: 20px;
      color: var(--ink-soft);
      margin: 0 0 32px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      gap: 6px;
      margin: 0 auto 28px;
      max-width: 360px;
    }
    .day {
      aspect-ratio: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 14px;
      color: var(--ink-soft);
      border-bottom: 1px dashed rgba(44, 37, 32, 0.15);
    }
    .cell {
      aspect-ratio: 1;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      color: var(--accent);
    }
    .status {
      display: inline-block;
      padding: 8px 20px;
      background: var(--paper-dim);
      border-radius: 24px;
      font-size: 16px;
      color: var(--ink-soft);
      margin-top: 8px;
    }
    .footer {
      margin-top: 28px;
      font-size: 14px;
      color: var(--ink-soft);
    }
    @media (max-width: 480px) {
      h1 { font-size: 48px; }
      .card { padding: 32px 24px; }
    }
  </style>
</head>
<body>
  <main class="card">
    <h1>planyr</h1>
    <p class="tagline">a weekly planner, the bullet-journal way</p>

    <div class="grid" aria-hidden="true">
      <div class="day">M</div><div class="day">T</div><div class="day">W</div><div class="day">T</div><div class="day">F</div><div class="day">S</div><div class="day">S</div>
      <div class="cell">&bull;</div><div class="cell">/</div><div class="cell">&#10003;</div><div class="cell">&bull;</div><div class="cell">&#9675;</div><div class="cell"></div><div class="cell"></div>
    </div>

    <span class="status">coming soon</span>

    <p class="footer">plan your week. mark your days. migrate the rest.</p>
  </main>
</body>
</html>`;

const SECURITY_HEADERS = {
  "strict-transport-security": "max-age=63072000; includeSubDomains; preload",
  "x-content-type-options": "nosniff",
  "x-frame-options": "DENY",
  "referrer-policy": "strict-origin-when-cross-origin",
};

export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/og-image.png") {
      const binary = atob(OG_IMAGE_B64);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
      return new Response(bytes, {
        headers: {
          "content-type": "image/png",
          "cache-control": "public, max-age=86400, immutable",
          ...SECURITY_HEADERS,
        },
      });
    }

    return new Response(HTML, {
      headers: {
        "content-type": "text/html; charset=UTF-8",
        "cache-control": "public, max-age=300",
        ...SECURITY_HEADERS,
      },
    });
  },
};
