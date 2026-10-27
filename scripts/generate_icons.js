const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

function createPng(width, height, getPixelRgba) {
  const rowSize = 1 + width * 4;
  const rawData = Buffer.alloc(rowSize * height);

  for (let y = 0; y < height; y++) {
    const rowOffset = y * rowSize;
    rawData[rowOffset] = 0; // Filter byte: None

    for (let x = 0; x < width; x++) {
      const pixelOffset = rowOffset + 1 + x * 4;
      const [r, g, b, a] = getPixelRgba(x, y, width, height);
      rawData[pixelOffset] = r;
      rawData[pixelOffset + 1] = g;
      rawData[pixelOffset + 2] = b;
      rawData[pixelOffset + 3] = a;
    }
  }

  const compressed = zlib.deflateSync(rawData);

  function makeChunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);

    const typeAndData = Buffer.concat([Buffer.from(type, 'ascii'), data]);
    const crc = Buffer.alloc(4);
    crc.writeUInt32BE(crc32(typeAndData), 0);

    return Buffer.concat([len, typeAndData, crc]);
  }

  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // 8 bits per channel
  ihdr[9] = 6; // RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace

  const ihdrChunk = makeChunk('IHDR', ihdr);
  const idatChunk = makeChunk('IDAT', compressed);
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([sig, ihdrChunk, idatChunk, iendChunk]);
}

// CRC32 calculation table
const crcTable = new Uint32Array(256);
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) {
    if (c & 1) c = 0xedb88320 ^ (c >>> 1);
    else c = c >>> 1;
  }
  crcTable[n] = c;
}

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

// Point in triangle test (barycentric coordinates)
function pointInTriangle(px, py, ax, ay, bx, by, cx, cy) {
  const v0x = cx - ax, v0y = cy - ay;
  const v1x = bx - ax, v1y = by - ay;
  const v2x = px - ax, v2y = py - ay;

  const dot00 = v0x * v0x + v0y * v0y;
  const dot01 = v0x * v1x + v0y * v1y;
  const dot02 = v0x * v2x + v0y * v2y;
  const dot11 = v1x * v1x + v1y * v1y;
  const dot12 = v1x * v2x + v1y * v2y;

  const invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
  const u = (dot11 * dot02 - dot01 * dot12) * invDenom;
  const v = (dot00 * dot12 - dot01 * dot02) * invDenom;

  return (u >= 0) && (v >= 0) && (u + v <= 1);
}

// Distance from point to segment
function distToSegment(px, py, x1, y1, x2, y2) {
  const l2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1);
  if (l2 === 0) return Math.hypot(px - x1, py - y1);
  let t = ((px - x1) * (x2 - x1) + (py - y1) * (y2 - y1)) / l2;
  t = Math.max(0, Math.min(1, t));
  return Math.hypot(px - (x1 + t * (x2 - x1)), py - (y1 + t * (y2 - y1)));
}

// Hex color parser
function parseHex(hex) {
  const c = parseInt(hex.replace('#', ''), 16);
  return [(c >> 16) & 255, (c >> 8) & 255, c & 255];
}

function renderIsohedronIcon(w, h, isNotification = false) {
  return (x, y) => {
    const cx = w / 2;
    const cy = h / 2;
    const R = Math.min(w, h) * (isNotification ? 0.42 : 0.38);

    // Compute outer 6 vertices
    const outer = [];
    for (let i = 0; i < 6; i++) {
      const angle = -Math.PI / 2 + i * (Math.PI / 3);
      outer.push([cx + R * Math.cos(angle), cy + R * Math.sin(angle)]);
    }

    // Compute inner 3 vertices
    const innerR = R * 0.48;
    const inner = [];
    for (let i = 0; i < 3; i++) {
      const angle = -Math.PI / 2 + i * (2 * Math.PI / 3);
      inner.push([cx + innerR * Math.cos(angle), cy + innerR * Math.sin(angle)]);
    }

    const facets = [
      { pts: [inner[0], inner[1], inner[2]], color: '#D91A2A', notifAlpha: 255 },
      { pts: [outer[0], inner[0], outer[5]], color: '#3B8EE8', notifAlpha: 190 },
      { pts: [outer[0], outer[1], inner[0]], color: '#5CA3EE', notifAlpha: 220 },
      { pts: [outer[1], inner[1], inner[0]], color: '#1A6FBF', notifAlpha: 170 },
      { pts: [outer[1], outer[2], inner[1]], color: '#165FA4', notifAlpha: 150 },
      { pts: [outer[2], outer[3], inner[1]], color: '#114B82', notifAlpha: 130 },
      { pts: [outer[3], inner[2], inner[1]], color: '#0D3B68', notifAlpha: 110 },
      { pts: [outer[3], outer[4], inner[2]], color: '#135390', notifAlpha: 140 },
      { pts: [outer[4], outer[5], inner[2]], color: '#1A6FBF', notifAlpha: 160 },
      { pts: [outer[5], inner[0], inner[2]], color: '#2E82DD', notifAlpha: 180 },
    ];

    // Background color
    let baseR = 245, baseG = 240, baseB = 232, baseA = 255; // #F5F0E8
    if (isNotification) {
      baseA = 0;
    } else {
      // Rounded squircle container
      const cornerR = w * 0.22;
      const dx = Math.max(0, Math.abs(x - cx) - (cx - cornerR));
      const dy = Math.max(0, Math.abs(y - cy) - (cy - cornerR));
      const distOutside = Math.hypot(dx, dy);
      if (distOutside > cornerR) {
        return [0, 0, 0, 0]; // Transparent outside squircle
      }
    }

    // Check edges for facet border stroke
    let minEdgeDist = 999;
    const allEdges = [
      [inner[0], inner[1]], [inner[1], inner[2]], [inner[2], inner[0]],
      [outer[0], inner[0]], [outer[5], inner[0]],
      [outer[1], outer[0]], [outer[1], inner[0]], [outer[1], inner[1]],
      [outer[2], outer[1]], [outer[2], inner[1]],
      [outer[3], outer[2]], [outer[3], inner[1]], [outer[3], inner[2]],
      [outer[4], outer[3]], [outer[4], inner[2]],
      [outer[5], outer[4]], [outer[5], inner[2]],
      [outer[0], outer[5]],
    ];

    for (const [p1, p2] of allEdges) {
      const d = distToSegment(x, y, p1[0], p1[1], p2[0], p2[1]);
      if (d < minEdgeDist) minEdgeDist = d;
    }

    // Determine facet
    let matchedFacet = null;
    for (const f of facets) {
      if (pointInTriangle(x, y, f.pts[0][0], f.pts[0][1], f.pts[1][0], f.pts[1][1], f.pts[2][0], f.pts[2][1])) {
        matchedFacet = f;
        break;
      }
    }

    const strokeThresh = Math.max(0.7, w * 0.014);

    if (matchedFacet) {
      if (isNotification) {
        if (minEdgeDist < strokeThresh) {
          return [255, 255, 255, 255];
        }
        return [255, 255, 255, matchedFacet.notifAlpha];
      } else {
        if (minEdgeDist < strokeThresh) {
          return [245, 240, 232, 255]; // Linen dividing lines
        }
        const [fr, fg, fb] = parseHex(matchedFacet.color);
        return [fr, fg, fb, 255];
      }
    }

    // Outer edge stroke
    let minOuterDist = 999;
    for (let i = 0; i < 6; i++) {
      const p1 = outer[i];
      const p2 = outer[(i + 1) % 6];
      const d = distToSegment(x, y, p1[0], p1[1], p2[0], p2[1]);
      if (d < minOuterDist) minOuterDist = d;
    }

    if (minOuterDist < strokeThresh * 1.5) {
      if (isNotification) {
        return [255, 255, 255, 120];
      }
      return [14, 55, 96, 200];
    }

    return [baseR, baseG, baseB, baseA];
  };
}

// Generate all densities
const targets = [
  { path: 'android/app/src/main/res/mipmap-mdpi/ic_launcher.png', size: 48, notif: false },
  { path: 'android/app/src/main/res/mipmap-hdpi/ic_launcher.png', size: 72, notif: false },
  { path: 'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', size: 96, notif: false },
  { path: 'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', size: 144, notif: false },
  { path: 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', size: 192, notif: false },
  { path: 'android/app/src/main/res/drawable/ic_notification.png', size: 48, notif: true },
  { path: 'android/app/src/main/res/drawable/ic_stat_notify.png', size: 48, notif: true },
];

for (const t of targets) {
  const pixelFn = renderIsohedronIcon(t.size, t.size, t.notif);
  const pngBuf = createPng(t.size, t.size, pixelFn);
  fs.writeFileSync(t.path, pngBuf);
  console.log(`Generated ${t.path} (${t.size}x${t.size}) - ${pngBuf.length} bytes`);
}
