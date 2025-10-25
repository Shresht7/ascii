//@ts-check

// ------------
// DOM ELEMENTS
// ------------

const searchInput = /** @type {HTMLInputElement} */ (document.getElementById('search-input'))
const asciiTable = /** @type {HTMLTableElement} */ (document.getElementById('ascii-table'))
const tableRows = asciiTable.getElementsByTagName('tr')

searchInput.addEventListener('input', () => {
    const searchTerm = searchInput.value.toLowerCase()

    // Start from 1 to skip the header row
    for (let i = 1; i < tableRows.length; i++) {
        const row = tableRows[i]
        const rowText = row.textContent.toLowerCase()
        const matches = rowText.includes(searchTerm)
        row.classList.toggle('hidden', !matches)
        row.classList.toggle('highlight', matches)
    }
})

