import { updateFlashcardTables, rowToJSON, storeLink, buildTable, expandContractRow } from "../utilities.js";

// Run buildPage when the page is loaded
document.addEventListener("DOMContentLoaded", buildPage())

/**
 * Populates the flashcard page with content
 */
function buildPage() {
    // Compose request for finalize tables
    const payload = {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify({})
    };

    fetch("/finalize/data", payload)
        .then(response => response.json())
        .then(data => insertFinalizeTables(data));
}

function insertFinalizeTables(data) {
    const tableBox = document.querySelector(".table-box");
    tableBox.innerHTML = ""

    // https://stackoverflow.com/questions/494143/creating-a-new-dom-element-from-an-html-string-using-built-in-dom-methods-or-pro/35385518#35385518
    for (let key in data) {
        const record = data[key];
        const template = document.createElement("template");
        template.innerHTML = record["html"];
        const tableHTML = template.content.firstChild;
        tableHTML.id = record["id"];
        tableBox.appendChild(tableHTML);
    };
}

function paginate(e) {
    e.preventDefault();

    // Get the form data
    const name = e.submitter.name;
    let value = e.submitter.value;

    const body = {
        "direction": value
    }

    const payload = {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify(body)
    };

    fetch("/finalize/data", payload)
        .then(response => response.json())
        .then(data => insertFinalizeTables(data));
}

document.expandContractRow = expandContractRow;
document.paginate = paginate;