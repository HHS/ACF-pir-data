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
        // Extract HTML
        const tableDiv = document.createElement("div");
        tableDiv.className = "finalize-table-div";

        const record = data[key];
        const template = document.createElement("template");
        template.innerHTML = record["html"];
        const tableHTML = template.content.firstChild;
        tableHTML.innerHTML = tableHTML.innerHTML.replace("flashcard-question-table", record["id"])
        tableHTML.id = record["id"];

        // Remove store buttons
        const storeButtons = tableHTML.querySelectorAll("button[onclick='storeLink(event)']")
        storeButtons.forEach(element => element.remove())

        // Add confirm button
        const confirmButton = document.createElement("button");
        confirmButton.classList.add(...["wrapper-button", "primary-button"]);
        confirmButton.innerHTML = "Confirm";
        confirmButton.setAttribute("onclick", "commitLink(event)");
        confirmButton.name = "confirm";
        confirmButton.value = record["id"];

        // Add deny button
        const denyButton = document.createElement("button");
        denyButton.classList.add(...["wrapper-button", "primary-button", "deny-button"]);
        denyButton.innerHTML = "Deny";
        denyButton.setAttribute("onclick", "commitLink(event)");
        denyButton.name = "deny";
        denyButton.value = record["id"];

        // Create button container
        const buttonContainer = document.createElement("div");
        buttonContainer.className = "button-container";
        buttonContainer.appendChild(denyButton);
        buttonContainer.appendChild(confirmButton);

        // Render the content
        tableDiv.appendChild(tableHTML);
        tableDiv.appendChild(buttonContainer);
        tableBox.appendChild(tableDiv);
    };
}

function paginate(e) {
    e.preventDefault();

    // Get the form data
    try {
        var name = e.submitter.name;
        var value = e.submitter.value;
    } catch {
        var name = e.target.name;
        var value = e.target.value;
    }

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

function commitLink(e) {
    e.preventDefault();

    let button = e.target;

    const body = {
        "action": button.name,
        "id": button.value
    }

    const payload = {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify(body)
    };

    fetch("/review/link", payload)
        .then(response => { 
            const tableBox = document.querySelector(".table-box");
            tableBox.innerHTML = "";
            buildPage();
        })
}

document.expandContractRow = expandContractRow;
document.paginate = paginate;
document.commitLink = commitLink;