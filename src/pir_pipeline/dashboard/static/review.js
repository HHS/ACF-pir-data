import { rowToJSON } from "./utilities.js"

function buildFlashcardPage(e) {
    const element = e.target;
    initializeFlashcards(element);
}

function initializeFlashcards(elem) {
    const reviewType = elem.getAttribute("value");

    const body = {
        "for": "flashcard",
        "review-type": reviewType
    };
    const payload = {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify(body)
    };

    fetch("/review/data", payload)
        .then(response => response.json())
        .then(async (data) => {
            await fetch("/review/flashcard")
                .then(response => response.text())
                .then(html => document.writeln(html))

            document.getElementById("review-type-input").value = reviewType;
            await updateFlashcardTables(data)
        })
}

async function flashcardAction(e) {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);
    const name = e.submitter.name;
    let value = e.submitter.value;
    if (value == "confirm") {
        const questionTable = document.getElementById("flashcard-question-table");
        let baseRecord = rowToJSON(questionTable.getElementsByTagName("tr")[1]);
        const linkDetails = {
            "link_type": value,
            "base_question_id": baseRecord.question_id,
            "base_uqid": baseRecord.uqid,
            "match_question_id": null,
            "match_uqid": null
        }

        const payload = {
            "action": "build",
            "data": linkDetails
        }

        await fetch("/review/link", {
            "method": "POST",
            "headers": {
                "Content-type": "application/json"
            },
            "body": JSON.stringify(payload)
        })
        value = "next";
    }
    formData.append(name, value);

    await fetch("/review/flashcard", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

function updateFlashcardTables(data) {
    const questionTable = document.getElementById("flashcard-question-table");
    if (questionTable) {
        var question = buildReviewTable(data["question"], questionTable);
    } else {
        var question = buildReviewTable(data["question"]);
    }
    question.id = "flashcard-question-table";
    question.className = "table table-hover";

    const matchesTable = document.getElementById("flashcard-matches-table");
    if (matchesTable) {
        var matches = buildReviewTable(data["matches"], matchesTable);
    } else {
        var matches = buildReviewTable(data["matches"]);
    }
    matches.id = "flashcard-matches-table";
    matches.className = "table table-hover";

    const tables = {
        "question": question.outerHTML,
        "matches": matches.outerHTML
    }

    return Promise.resolve(tables)
}

function storeLink(event) {
    const button = event.target;
    const matchRow = button.closest("tr");
    const baseRow = document.getElementById("flashcard-question-table").getElementsByTagName("tr")[1];
    const baseRecord = rowToJSON(baseRow);
    const matchRecord = rowToJSON(matchRow)

    const linkDetails = {
        "link_type": button.value,
        "base_question_id": baseRecord.question_id,
        "base_uqid": baseRecord.uqid,
        "match_question_id": matchRecord.question_id,
        "match_uqid": matchRecord.uqid
    }

    const payload = {
        "action": "build",
        "data": linkDetails
    }

    fetch("/review/link", {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify(payload)
    })
}

function buildReviewTable(data, table = document.createElement("table")) {
    // Constant buttons
    const expandButtonBase = document.createElement("button");
    expandButtonBase.className = "accordion-button collapsed";
    expandButtonBase.setAttribute("type", "button");
    expandButtonBase.setAttribute("data-bs-toggle", "collapse");
    expandButtonBase.setAttribute("aria-expanded", "false");

    const accordionDivBase = document.createElement("div");
    accordionDivBase.className = "accordion";

    const linkButtonBase = document.createElement("button");
    linkButtonBase.className = "btn btn-primary";
    linkButtonBase.setAttribute("onclick", "storeLink(event)");

    const reviewType = document.getElementById("review-type-input");

    // Set table header row
    table.innerHTML = '';

    let header = data["columns"];
    let head = document.createElement("thead");
    let headerRow = document.createElement("tr");
    head.appendChild(headerRow)

    // Add column headers
    for (let i = 0; i < header.length; i++) {
        const column = document.createElement("th");
        column.innerHTML = header[i];
        headerRow.appendChild(column);
    }
    let actionsColumn = document.createElement("th");
    actionsColumn.innerHTML = "Action"; 
    headerRow.appendChild(actionsColumn);
    table.appendChild(head);

    let body = document.createElement("tbody");
    let record_num = 0;
    for (let key in data) {
        if (key == "columns") {
            continue
        }

        const expandButton = expandButtonBase.cloneNode(true);
        expandButton.innerHTML = "";
        
        
        const accordionDiv = accordionDivBase.cloneNode(true);

        // Get all records associated with this question_id/uqid
        const records = data[key];

        // Loop through each record
        for (let i = 0; i < records.length; i++) {
            const row = document.createElement("tr");

            // Add cells for each value in a record
            let row_data = records[i];
            for (let key in row_data) {
                const cell = document.createElement("td");
                cell.innerHTML = row_data[key];
                cell.setAttribute("name", key);
                row.appendChild(cell);
            }
                
            const actionsCell = document.createElement("td");
            const trID = table.id + "-tr-" + record_num + "-" + i;
            expandButton.setAttribute("data-bs-target", `tr[id*="${table.id}-tr-${record_num}-"]`);

            if (i > 0) {
                row.className = `accordion-collapse collapse collapsible-row-${record_num}`;
                row.id = `collapse-${trID}`;
                let expandValue = expandButton.getAttribute("aria-controls")
                if (expandValue) {
                    expandValue += ` ${row.id}`;
                }
                else {
                    expandValue = row.id;
                }
                expandButton.setAttribute("aria-controls", expandValue);
            }
            else {
                accordionDiv.appendChild(expandButton);
                actionsCell.appendChild(accordionDiv);
                const linkButton = linkButtonBase.cloneNode(true); 
                if (reviewType && (reviewType.value == "unlinked" || reviewType.value == "intermittent")) {
                    linkButton.value = "link";
                    linkButton.innerHTML = "Link";
                } else {
                    linkButton.value = "unlink";
                    linkButton.innerHTML = "Unlink";
                }
                if (table.id != "flashcard-question-table") {
                    actionsCell.appendChild(linkButton);
                }
            }

            row.appendChild(actionsCell);
            body.appendChild(row);
        }
        record_num += 1
    }
    table.appendChild(body);
    return table
}

document.storeLink = storeLink;
document.buildFlashcardPage = buildFlashcardPage;
document.flashcardAction = flashcardAction;

export {
    updateFlashcardTables,
    flashcardAction
}