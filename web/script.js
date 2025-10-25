//@ts-check

// ------------
// DOM ELEMENTS
// ------------

const searchInput = /** @type {HTMLInputElement} */ (document.getElementById('search-input'));
const asciiTable = /** @type {HTMLTableElement} */ (document.getElementById('ascii-table'));
const tableBody = /** @type {HTMLTableSectionElement} */ (asciiTable.tBodies[0]);
const originalRows = Array.from(tableBody.getElementsByTagName('tr'));

/**
 * @typedef {object} RowData
 * @property {string} char
 * @property {string} dec
 * @property {string} hex
 * @property {string} oct
 * @property {string} bin
 * @property {number} score
 * @property {HTMLTableRowElement} element
 */

/** @type {RowData[]} */
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
 * @param {RowData} rowData 
 * @param {string} searchTerm 
 */
function calculateScore(rowData, searchTerm) {
    let score = 0;
    if (!searchTerm) { return 0; }

    // Character column
    if (rowData.char === searchTerm) {
        score += SCORE.CHAR_EXACT;
    } else if (rowData.char.includes(searchTerm)) {
        score += SCORE.CHAR_PARTIAL;
    }

    // Decimal column
    if (rowData.dec === searchTerm) {
        score += SCORE.DEC_EXACT;
    } else if (rowData.dec.includes(searchTerm)) {
        score += SCORE.DEC_PARTIAL;
    }

    // Hex column
    if (rowData.hex === searchTerm) {
        score += SCORE.HEX_EXACT;
    } else if (rowData.hex.includes(searchTerm)) {
        score += SCORE.HEX_PARTIAL;
    }

    // Binary column
    if (rowData.bin === searchTerm) {
        score += SCORE.BIN_EXACT;
    } else if (rowData.bin.includes(searchTerm)) {
        score += SCORE.BIN_PARTIAL;
    }

    // Octal column
    if (rowData.oct === searchTerm) {
        score += SCORE.OCT_EXACT;
    } else if (rowData.oct.includes(searchTerm)) {
        score += SCORE.OCT_PARTIAL;
    }

    return score;
}

function updateTable() {
    const searchTerm = searchInput.value.toLowerCase();

    // if search term is empty, show all rows in original order
    if (!searchTerm) {
        originalRows.forEach(row => {
            tableBody.appendChild(row);
            row.classList.remove('hidden');
        });
        // remove highlight from all rows
        tableData.forEach(rowData => {
            rowData.element.classList.remove('highlight');
        });
        return;
    }

    // Calculate scores
    tableData.forEach(rowData => {
        rowData.score = calculateScore(rowData, searchTerm);
    });

    // Filter and sort
    const sortedData = tableData
        .filter(rowData => rowData.score > 0)
        .sort((a, b) => b.score - a.score);

    // Hide all rows first
    originalRows.forEach(row => row.classList.add('hidden'));

    // Append sorted rows and highlight them
    sortedData.forEach(rowData => {
        rowData.element.classList.remove('hidden');
        rowData.element.classList.add('highlight');
        tableBody.appendChild(rowData.element);
    });

    // Un-highlight rows that are not in the sorted list
    const unhighlightedData = tableData.filter(rowData => rowData.score === 0);
    unhighlightedData.forEach(rowData => {
        rowData.element.classList.remove('highlight');
    });
}


searchInput.addEventListener('input', updateTable);
