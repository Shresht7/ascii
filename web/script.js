//@ts-check

// ------------
// DOM ELEMENTS
// ------------

const searchInput = /** @type {HTMLInputElement} */ (document.getElementById('search-input'));
const asciiTable = /** @type {HTMLTableElement} */ (document.getElementById('ascii-table'));
const tableBody = /** @type {HTMLTableSectionElement} */ (asciiTable.tBodies[0]);
const noResultsMessage = /** @type {HTMLParagraphElement} */ (document.getElementById('no-results-message'));

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
 * @property {number[]} cellMatch - Per-cell match type (0=none, 1=partial, 2=exact).
 * @property {HTMLTableRowElement} element - A direct reference to the <tr> DOM element.
 */

/**
 * An array of RowData objects, built from the pre-rendered table rows.
 * This provides a fast, structured way to search and links data to the generated DOM elements.
 * @type {RowData[]}
 */
const tableData = [...tableBody.rows].map(row => ({
    char: row.cells[0].textContent.toLowerCase(),
    dec: row.cells[1].textContent.toLowerCase(),
    hex: row.cells[2].textContent.toLowerCase(),
    oct: row.cells[3].textContent.toLowerCase(),
    bin: row.cells[4].textContent.toLowerCase(),
    score: 0,
    cellMatch: [0, 0, 0, 0, 0],
    element: row
}));

const originalRows = [...tableBody.rows];


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
 * @returns {{ score: number, cellMatch: number[] }} The calculated score and per-cell match types.
 */
function calculateWeightedScore(rowData, searchTerm) {
    let score = 0;
    /** @type {number[]} */
    const cellMatch = [0, 0, 0, 0, 0];

    // Character column
    if (rowData.char === searchTerm) { score += SCORE.CHAR_EXACT; cellMatch[0] = 2; }
    else if (rowData.char.includes(searchTerm)) { score += SCORE.CHAR_PARTIAL; cellMatch[0] = 1; }

    // Decimal column
    if (rowData.dec === searchTerm) { score += SCORE.DEC_EXACT; cellMatch[1] = 2; }
    else if (rowData.dec.includes(searchTerm)) { score += SCORE.DEC_PARTIAL; cellMatch[1] = 1; }

    // Hex column
    if (rowData.hex === searchTerm) { score += SCORE.HEX_EXACT; cellMatch[2] = 2; }
    else if (rowData.hex.includes(searchTerm)) { score += SCORE.HEX_PARTIAL; cellMatch[2] = 1; }

    // Octal column
    if (rowData.oct === searchTerm) { score += SCORE.OCT_EXACT; cellMatch[3] = 2; }
    else if (rowData.oct.includes(searchTerm)) { score += SCORE.OCT_PARTIAL; cellMatch[3] = 1; }

    // Binary column
    if (rowData.bin === searchTerm) { score += SCORE.BIN_EXACT; cellMatch[4] = 2; }
    else if (rowData.bin.includes(searchTerm)) { score += SCORE.BIN_PARTIAL; cellMatch[4] = 1; }

    return { score, cellMatch };
}

// ---------------
// VIEW TRANSITION
// ---------------

/**
 * Calls document.startViewTransition if available, otherwise invokes the callback directly
 * @param {() => void} callback The function to execute within the view transition
 */
function withViewTransition(callback) {
    if (document.startViewTransition) {
        document.startViewTransition(callback);
    } else {
        callback();
    }
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
        noResultsMessage.classList.add('hidden');
        originalRows.forEach(row => {
            tableBody.appendChild(row);
            row.classList.remove('hidden', 'highlight');
            for (let i = 0; i < 5; i++) {
                row.cells[i].classList.remove('highlight', 'exact-match');
            }
        });
        return;
    }

    // Calculate a score for each row based on the search mode and term.
    tableData.forEach(rowData => {
        let score = 0;
        /** @type {number[]} */
        let cellMatch = [0, 0, 0, 0, 0];
        const MAX_SCORE = 10000; // A high score for prefix searches to override weighted results.

        switch (searchMode) {
            case 'hex':
                if (rowData.hex === searchTerm) { score = MAX_SCORE; cellMatch[2] = 2; }
                else if (rowData.hex.includes(searchTerm)) { score = MAX_SCORE / 2; cellMatch[2] = 1; }
                break;
            case 'oct':
                if (rowData.oct === searchTerm) { score = MAX_SCORE; cellMatch[3] = 2; }
                else if (rowData.oct.includes(searchTerm)) { score = MAX_SCORE / 2; cellMatch[3] = 1; }
                break;
            case 'bin':
                if (rowData.bin === searchTerm) { score = MAX_SCORE; cellMatch[4] = 2; }
                else if (rowData.bin.includes(searchTerm)) { score = MAX_SCORE / 2; cellMatch[4] = 1; }
                break;
            case 'weighted':
            default: {
                const result = calculateWeightedScore(rowData, searchTerm);
                score = result.score;
                cellMatch = result.cellMatch;
                break;
            }
        }
        rowData.score = score;
        rowData.cellMatch = cellMatch;
    });

    // Filter out zero-score rows and sort the rest by score in descending order.
    const sortedData = tableData
        .filter(rowData => rowData.score > 0)
        .sort((a, b) => b.score - a.score);

    // Hide all rows to prepare for re-ordering.
    originalRows.forEach(row => row.classList.add('hidden'));

    if (sortedData.length === 0) {
        noResultsMessage.textContent = `No results for "${rawSearchTerm}"`;
        noResultsMessage.classList.remove('hidden');
    } else {
        noResultsMessage.classList.add('hidden');
    }

    // Append the sorted rows back into the table and apply cell-level match styling.
    // This re-orders the DOM elements based on the search score.
    sortedData.forEach(rowData => {
        rowData.element.classList.remove('hidden');
        for (let i = 0; i < 5; i++) {
            const cell = rowData.element.cells[i];
            cell.classList.remove('highlight', 'exact-match');
            if (rowData.cellMatch[i] === 2) {
                cell.classList.add('exact-match');
            } else if (rowData.cellMatch[i] === 1) {
                cell.classList.add('highlight');
            }
        }
        tableBody.appendChild(rowData.element);
    });

    // Ensure rows that are not in the result set have no cell-level styling.
    const unhighlightedData = tableData.filter(rowData => rowData.score === 0);
    unhighlightedData.forEach(rowData => {
        rowData.element.classList.remove('highlight');
        for (let i = 0; i < 5; i++) {
            rowData.element.cells[i].classList.remove('highlight', 'exact-match');
        }
    });
}

// ------------
// URL HANDLING
// ------------

/**
 * @param {string} query The URL Search Query
 */
function updateURL(query) {
    const url = new URL(window.location.href);
    if (query) {
        url.searchParams.set('q', query);
    } else {
        url.searchParams.delete('q');
    }
    history.replaceState({}, '', url.toString());
}

function getSearchQueryFromURL() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('q');
}

// -----------------
// COPY TO CLIPBOARD
// -----------------

/** The duration for which the "Copied!" feedback message is displayed after a successful copy action. */
const COPY_FEEDBACK_MS = 1000;

/** @type {Map<HTMLTableCellElement, NodeJS.Timeout>} */
const activeCopyTimeouts = new Map();

/**
 * Displays a temporary "Copied!" feedback message in the specified table cell.
 * @param {HTMLTableCellElement} cell The table cell to show feedback on
 */
function showCopyFeedback(cell) {
    const existingTimeout = activeCopyTimeouts.get(cell);
    if (existingTimeout) clearTimeout(existingTimeout);

    cell.classList.add('copied');
    cell.textContent = 'Copied!';

    const timeoutId = setTimeout(() => {
        cell.classList.remove('copied');
        cell.textContent = cell.dataset.value || '';
        activeCopyTimeouts.delete(cell);
    }, COPY_FEEDBACK_MS);

    activeCopyTimeouts.set(cell, timeoutId);
}

/**
 * Copies the value of a table cell to the clipboard and provides visual feedback
 * @param {HTMLTableCellElement} cell The table cell to copy from
 */
function copyCellValue(cell) {
    const value = cell.dataset.value;
    if (value === undefined) return;

    navigator.clipboard.writeText(value)
        .then(() => showCopyFeedback(cell))
        .catch(err => console.error('Failed to copy to clipboard: ', err));
}

// Register a click event listener on the table body to handle cell clicks for copying values.
tableBody.addEventListener('click', event => {
    const cell = /** @type {HTMLElement} */ (event.target).closest('td');
    if (cell) copyCellValue(cell);
});

// ------------------
// KEYBOARD SHORTCUTS
// ------------------

/**
 * Registers keyboard shortcuts for the search input.
 * - `/` focuses the search input
 * - `Escape` blurs the search input
 */
document.addEventListener('keydown', event => {
    if (event.key === '/' && event.target !== searchInput) {
        const tag = /** @type {HTMLElement} */ (event.target).tagName;
        if (tag !== 'INPUT' && tag !== 'TEXTAREA') {
            event.preventDefault();
            searchInput.focus();
        }
    }

    if (event.key === 'Escape' && document.activeElement === searchInput) {
        searchInput.value = '';
        searchInput.blur();
        updateURL('');
        withViewTransition(() => updateTable());
    }
});

// --------------
// INITIALIZATION
// --------------

/** The initialization logic */
function init() {
    const query = getSearchQueryFromURL();
    if (query) {
        searchInput.value = query;
    }

    withViewTransition(() => updateTable());
    searchInput.addEventListener('input', () => {
        updateURL(searchInput.value);
        withViewTransition(() => updateTable());
    });
}

init();
