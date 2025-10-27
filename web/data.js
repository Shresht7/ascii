
const controlCharacterNames = [
    'NUL', 'SOH', 'STX', 'ETX', 'EOT', 'ENQ', 'ACK', 'BEL', 'BS', 'HT', 'LF', 'VT', 'FF', 'CR', 'SO', 'SI',
    'DLE', 'DC1', 'DC2', 'DC3', 'DC4', 'NAK', 'SYN', 'ETB', 'CAN', 'EM', 'SUB', 'ESC', 'FS', 'GS', 'RS', 'US'
];

/**
 * An array containing the complete 128-character ASCII set.
 * Each entry includes the character representation and its decimal, hex, octal, and binary codes.
 * @type {{char: string, dec: string, hex: string, oct: string, bin: string}[]}
 */
export const ASCII_DATA = [];

for (let i = 0; i <= 127; i++) {
    let char;
    if (i <= 31) {
        char = controlCharacterNames[i];
    } else if (i === 127) {
        char = 'DEL';
    } else {
        char = String.fromCharCode(i);
    }

    ASCII_DATA.push({
        char: char,
        dec: i.toString(),
        hex: i.toString(16),
        oct: i.toString(8),
        bin: i.toString(2),
    });
}
