import { updateTable, rowToJSON, updateFlashcardTables, storeLink, buildReviewTable } from "../utilities.js";

const searchForm = document.getElementById("search-form");
const modalSearchForm = document.getElementById("modal-search-form");
const searchModal = document.getElementById("search-modal");

searchForm.addEventListener("submit", async (e) => {
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
    e.preventDefault();
    updateTable(e);
})

modalSearchForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (!document.getElementById("modal-keyword-search").value) {
        return;
    };

    const form = e.target;
    const formData = new FormData(form);
    const table = document.getElementById("flashcard-matches-table");

    fetch("/search", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => buildReviewTable(data, table))
})

function getFlashcardData(e) {
    e.preventDefault();
    const element = e.target;

    const row = element.closest('tr');
    const rowRecord = rowToJSON(row);

    searchModal.setAttribute("open", "true");
    searchModal.removeAttribute("hidden");

    fetch("/search/data", {
        "method": "POST",
        "headers": { "Content-type": "application/json" },
        "body": JSON.stringify(rowRecord)
    })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

function commitChanges(e) {
    e.preventDefault();
    // Commit changes
    const payload = {
        "action": "finalize",
        "data": ""
    }

    fetch("/review/link", {
        "method": "POST",
        "headers": { "Content-type": "application/json" },
        "body": JSON.stringify(payload)
    })

    // Close modal
    searchModal.removeAttribute("open");
}

// Observe the modal and remove content if it is closed
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