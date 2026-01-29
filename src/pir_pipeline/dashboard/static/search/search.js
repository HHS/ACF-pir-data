import { updateTable, rowToJSON, updateFlashcardTables, storeLink, buildTable, expandContractRow } from "../utilities.js";

// Constant forms and modals
const searchForm = document.getElementById("search-form");
const modalSearchForm = document.getElementById("modal-search-form");
const searchModal = document.getElementById("search-modal");

searchForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    // Flash an error if keyword is not provided
    if (!document.getElementById("keyword-search").value) {
        let data = {
            "error": "Missing keyword"
        }
        fetch("/search", { "method": "POST", "headers": { "Content-type": "application/json" }, "body": JSON.stringify(data) })
        return;
    }
    // Removed flashed messages if successful
    const flashedDivs = document.getElementsByClassName("flash");
    for (let i = 0; i < flashedDivs.length; i++) {
        flashedDivs[i].remove();
    }

    // Update the search table
    updateTable(e);
})

modalSearchForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    // If no search term in the modal keyword search, do nothing
    if (!document.getElementById("modal-keyword-search").value) {
        return;
    };

    // Get the search results and update the matches table
    const form = e.target;
    const formData = new FormData(form);
    const table = document.getElementById("flashcard-matches-table");

    fetch("/search", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => buildTable(data, table))
})

/**
 * Get the data necessary to review/edit the target question and show the editing modal
 * 
 * @param {*} e The event that triggered the getFlashcardData function
 */
function getFlashcardData(e) {
    e.preventDefault();

    const element = e.target;

    const row = element.closest('tr');
    const rowRecord = rowToJSON(row);

    // Open the modal
    searchModal.setAttribute("open", "true");
    searchModal.removeAttribute("hidden");

    // Update the modal
    fetch("/search/data", {
        "method": "POST",
        "headers": { "Content-type": "application/json" },
        "body": JSON.stringify(rowRecord)
    })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

/**
 * Commit all changes to the database
 * 
 * @param {*} e The event that triggered comitting the changes
 */
function commitChanges(e) {
    e.preventDefault();

    const questionTable = document.getElementById("flashcard-question-table");

    // Commit changes to the database
    const payload = {
        "action": "store",
        "html": questionTable.outerHTML
    }

    fetch("/review/link", {
        "method": "POST",
        "headers": { "Content-type": "application/json" },
        "body": JSON.stringify(payload)
    })

    // Close modal
    searchModal.removeAttribute("open");
}

// Observe the modal and remove content if when is closed
// Adapted from https://stackoverflow.com/questions/41424989/javascript-listen-for-attribute-change
const observer = new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) {
        if (mutation.type === "attributes") {
            if (mutation.attributeName == "open" && mutation.oldValue == "true") {
                const tables = searchModal.getElementsByTagName("table");
                for (let i = 0; i < tables.length; i++) {
                    tables[i].innerHTML = ""
                }
            }
        }
    })
})

observer.observe(searchModal, {
    attributes: true,
    attributeOldValue: true
})

document.getFlashcardData = getFlashcardData;
document.storeLink = storeLink;
document.commitChanges = commitChanges;
document.expandContractRow = expandContractRow;