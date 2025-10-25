//@ts-check

// ------------
// DOM ELEMENTS
// ------------

const searchInput = /** @type {HTMLInputElement} */ (document.getElementById('search-input'));
const asciiTable = /** @type {HTMLTableElement} */ (document.getElementById('ascii-table'));
const tableBody = /** @type {HTMLTableSectionElement} */ (asciiTable.tBodies[0]);
const originalRows = Array.from(tableBody.getElementsByTagName('tr'));

// ----------------
// DATA PREPARATION
// ----------------

/**
 * A structured representation of a single row in the ASCII table.
 * @typedef {object} RowData
 * @property {string} char - The character representation (e.g., 'A', 'NUL').
 * @property {string} dec - The decimal code as a string.
 * @property {string} hex - The hexadecimal code as a string.
 * @property {string} oct - The octal code as a string.
 * @property {string} bin - The binary code as a string.
 * @property {number} score - The calculated search score for the row.
 * @property {HTMLTableRowElement} element - A direct reference to the <tr> DOM element.
 */

/**
 * An array of RowData objects, parsed from the static HTML table on page load.
 * This avoids repeated DOM queries and provides a fast, structured way to search.
 * @type {RowData[]}
 */
const tableData = originalRows.map(row => {
    const cells = row.getElementsByTagName('td');
    return {
        char: cells[0].textContent.toLowerCase(),
        dec: cells[1].textContent.toLowerCase(),
        hex: cells[2].textContent.toLowerCase(),
        oct: cells[3].textContent.toLowerCase(),
        bin: cells[4].textContent.toLowerCase(),
        score: 0,
        element: row
    };
});

// --------------
// SEARCH SCORING
// --------------

/**
 * Scoring constants for the weighted search algorithm.
 * The values are designed to create a clear priority order:
 * Character > Decimal > Hex > Binary > Octal.
 * An exact match in a lower-priority category is worth less than a
 * partial match in a higher-priority one.
 */
const SCORE = {
    CHAR_EXACT: 1000,
    CHAR_PARTIAL: 500,
    DEC_EXACT: 100,
    DEC_PARTIAL: 50,
    HEX_EXACT: 40,
    HEX_PARTIAL: 20,
    BIN_EXACT: 15,
    BIN_PARTIAL: 10,
    OCT_EXACT: 5,
    OCT_PARTIAL: 2,
};

/**
 * Calculates a score for a row based on the weighted algorithm.
 * @param {RowData} rowData - The data object for the row to score.
 * @param {string} searchTerm - The user's search term.
 * @returns {number} The calculated score.
 */
function calculateWeightedScore(rowData, searchTerm) {
    let score = 0;
    if (!searchTerm) return 0;

    // Character column
    if (rowData.char === searchTerm) score += SCORE.CHAR_EXACT;
    else if (rowData.char.includes(searchTerm)) score += SCORE.CHAR_PARTIAL;

    // Decimal column
    if (rowData.dec === searchTerm) score += SCORE.DEC_EXACT;
    else if (rowData.dec.includes(searchTerm)) score += SCORE.DEC_PARTIAL;

    // Hex column
    if (rowData.hex === searchTerm) score += SCORE.HEX_EXACT;
    else if (rowData.hex.includes(searchTerm)) score += SCORE.HEX_PARTIAL;

    // Binary column
    if (rowData.bin === searchTerm) score += SCORE.BIN_EXACT;
    else if (rowData.bin.includes(searchTerm)) score += SCORE.BIN_PARTIAL;

    // Octal column
    if (rowData.oct === searchTerm) score += SCORE.OCT_EXACT;
    else if (rowData.oct.includes(searchTerm)) score += SCORE.OCT_PARTIAL;

    return score;
}

// -----------
// DOM UPDATES
// -----------

/**
 * The main function that handles the search input and updates the table display.
 * It is called on every 'input' event from the search box.
 */
function updateTable() {
    const rawSearchTerm = searchInput.value.toLowerCase();
    let searchTerm = rawSearchTerm;
    let searchMode = 'weighted'; // Can be 'weighted', 'hex', 'oct', or 'bin'

    // Check for special prefixes (0x, 0o, 0b) to trigger a targeted search.
    if (searchTerm.startsWith('0x') && searchTerm.length > 2) {
        searchMode = 'hex';
        searchTerm = searchTerm.substring(2);
    } else if (searchTerm.startsWith('0o') && searchTerm.length > 2) {
        searchMode = 'oct';
        searchTerm = searchTerm.substring(2);
    } else if (searchTerm.startsWith('0b') && searchTerm.length > 2) {
        searchMode = 'bin';
        searchTerm = searchTerm.substring(2);
    }

    // If the search box is cleared, restore the table to its original state.
    if (!rawSearchTerm) {
        originalRows.forEach(row => {
            tableBody.appendChild(row);
            row.classList.remove('hidden', 'highlight');
        });
        return;
    }

    // Calculate a score for each row based on the search mode and term.
    tableData.forEach(rowData => {
        let score = 0;
        const MAX_SCORE = 10000; // A high score for prefix searches to override weighted results.

        switch (searchMode) {
            case 'hex':
                if (rowData.hex === searchTerm) score = MAX_SCORE;
                else if (rowData.hex.includes(searchTerm)) score = MAX_SCORE / 2;
                break;
            case 'oct':
                if (rowData.oct === searchTerm) score = MAX_SCORE;
                else if (rowData.oct.includes(searchTerm)) score = MAX_SCORE / 2;
                break;
            case 'bin':
                if (rowData.bin === searchTerm) score = MAX_SCORE;
                else if (rowData.bin.includes(searchTerm)) score = MAX_SCORE / 2;
                break;
            case 'weighted':
            default:
                score = calculateWeightedScore(rowData, searchTerm);
                break;
        }
        rowData.score = score;
    });

    // Filter out zero-score rows and sort the rest by score in descending order.
    const sortedData = tableData
        .filter(rowData => rowData.score > 0)
        .sort((a, b) => b.score - a.score);

    // Hide all rows to prepare for re-ordering.
    originalRows.forEach(row => row.classList.add('hidden'));

    // Append the sorted rows back into the table and apply the highlight style.
    // This re-orders the DOM elements based on the search score.
    sortedData.forEach(rowData => {
        rowData.element.classList.remove('hidden');
        rowData.element.classList.add('highlight');
        tableBody.appendChild(rowData.element);
    });

    // Ensure rows that are not in the result set are not highlighted.
    const unhighlightedData = tableData.filter(rowData => rowData.score === 0);
    unhighlightedData.forEach(rowData => {
        rowData.element.classList.remove('highlight');
    });
}

// --------------
// EVENT LISTENER
// --------------

searchInput.addEventListener('input', () => {
    document.startViewTransition(() => {
        updateTable()
    })
});
