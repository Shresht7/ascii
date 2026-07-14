// =========================
// ASCII Table Row Generator
// =========================

// Generates static <tr> elements from data.js and injects
// them into index.html between <tbody> and </tbody>.
//
// Usage: node web/generate-table.mjs
// Run this before deploying or committing changes to the table data.

// Library
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { ASCII_DATA } from './data.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function escapeHTML(s) {
    return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

let rows = '';
for (const item of ASCII_DATA) {
    const escaped = escapeHTML(item.char);
    rows += `                <tr>
                    <td data-value="${escaped}">${escaped}</td>
                    <td data-value="${item.dec}">${item.dec}</td>
                    <td data-value="${item.hex}">${item.hex}</td>
                    <td data-value="${item.oct}">${item.oct}</td>
                    <td data-value="${item.bin}">${item.bin}</td>
                </tr>\n`;
}

const indexPath = resolve(__dirname, 'index.html');
let html = readFileSync(indexPath, 'utf-8');

html = html.replace(
    /<tbody>[\s\S]*?<\/tbody>/,
    `<tbody>\n${rows}                </tbody>`
);

writeFileSync(indexPath, html, 'utf-8');
console.log(`Generated ${ASCII_DATA.length} ASCII table rows into index.html`);
