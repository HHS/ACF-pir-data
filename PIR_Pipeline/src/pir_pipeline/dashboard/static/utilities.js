function updateTable(event) {
    // Get the form data
    const form = event.srcElement;
    const formData = new FormData(form);

    // Get the table to be updated
    const tables = document.getElementsByTagName("table");
    const table = tables[0];

    fetch(document.URL, {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => {
        if (table.id.match("review")) {
            buildTable(data, table)
        } else {
            buildSearchTable(data, table)
        }
    });
}

function buildTable(data, table) {
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

    // Other constants
    let reviewType = document.getElementById("review-type");
    if (reviewType) {
        reviewType = reviewType.value;
    }

    // Set table header row
    table.innerHTML = '';

    let header = data[0];
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

    for (let i = 1; i < data.length; i++) {
        const row = document.createElement("tr");

        let row_data = data[i];
        for (let key in row_data) {
            const cell = document.createElement("td");
            cell.innerHTML = row_data[key];
            cell.setAttribute("name", key);
            row.appendChild(cell);
        }

        if (table.id == "review-results-table") {
            const divID = table.id + "-div-" + i;
            const trID = table.id + "-tr-" + i;
            const tdID = table.id + "-td-" + i;
            const expandButton = expandButtonBase.cloneNode(true);
            expandButton.innerHTML = "";
            expandButton.setAttribute("data-bs-target", `#collapse-${trID}`);
            expandButton.setAttribute("aria-controls", `collapse-${trID}`);
            expandButton.setAttribute("onclick", `getQuestionData(event, '${reviewType}')`);
            const accordionDiv = accordionDivBase.cloneNode(true);
            accordionDiv.appendChild(expandButton);
            
            const actionsCell = document.createElement("td");
            actionsCell.appendChild(accordionDiv);
            row.appendChild(actionsCell);

            // Create div to hold table
            const div = document.createElement("div");
            div.id = `collapse-${divID}`;

            // Create row and cell to hold div
            // Adapted from Claude logic, needed to maintain alignment
            var tr = document.createElement("tr");
            tr.className = "accordion-collapse collapse";
            tr.id = `collapse-${trID}`;
            const td = document.createElement("td");
            td.id = `collapse-${tdID}`;
            td.setAttribute("colspan", data.length);

            td.appendChild(div);
            tr.appendChild(td);
        }
        else if (table.id.includes("proposed-matches-table")) {
            const actionsCell = document.createElement("td");
            if (["unlinked", "intermittent"].find(item => item == reviewType)) {
                const linkButton = linkButtonBase.cloneNode(true);
                linkButton.value = "link";
                linkButton.innerHTML = "Link";
                actionsCell.append(linkButton);
            }
            else if (reviewType == "inconsistent") {
                const unlinkButton = linkButtonBase.cloneNode(true);
                unlinkButton.value = "unlink";
                unlinkButton.innerHTML = "Unlink";
                actionsCell.append(unlinkButton);
            }
            

            row.append(actionsCell);
        } 

        body.appendChild(row);
        if (table.id == "review-results-table") {
            body.appendChild(tr);
        }
    }

    table.appendChild(body);
    return table;
}

function rowToJSON(row) {
    const cells = row.getElementsByTagName("td");
    let record = {}
    for (let i = 0; i < cells.length; i++) {
        const cell = cells[i];
        const name = cell.getAttribute("name");
        if (name == null) continue;
        record[cell.getAttribute("name")] = cell.innerHTML;
    }
    return record
}

function getQuestionData(event, reviewType) {
    const row = event.srcElement.closest("tr");
    const button = event.srcElement
    const tr = document.getElementById(button.getAttribute("aria-controls"));
    const div = document.getElementById(tr.id.replace("-tr-", "-div-"));

    // Exit if the target div already contains a table (i.e. matches have been found once).
    let table = div.getElementsByTagName("table");
    if (table.length > 0) {
        return
    }

    let record = rowToJSON(row);
    let payload = {
        "review-type": reviewType,
        "record": record
    }
    
    fetch("/review/match", {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(payload)})
    .then(response => response.json())
    .then(data => fillMatchDiv(div, data));
}

function fillMatchDiv(div, data) {
    const table = document.createElement("table");
    const idNumber = div.id.replace("collapse-review-results-table-div-", "")
    table.className = "table table-hover";
    table.setAttribute("id", `proposed-matches-table-${idNumber}`);
    div.setAttribute("style", "width: 100%");
    div.appendChild(table);
    buildTable(data, table);
}

function buildSearchTable(data, table = document.createElement("table")) {
    // Constant buttons
    const expandButtonBase = document.createElement("button");
    expandButtonBase.className = "accordion-button collapsed";
    expandButtonBase.setAttribute("type", "button");
    expandButtonBase.setAttribute("data-bs-toggle", "collapse");
    expandButtonBase.setAttribute("aria-expanded", "false");

    const accordionDivBase = document.createElement("div");
    accordionDivBase.className = "accordion";

    const reviewButtonBase = document.createElement("button");
    reviewButtonBase.setAttribute("onclick", "getFlashcardData(event)");
    reviewButtonBase.className = "btn btn-primary";

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

        const actionsCell = document.createElement("td");

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
                if (row_data["year"].match(",|-")) {
                    accordionDiv.appendChild(expandButton);
                }
                actionsCell.appendChild(accordionDiv);
                const reviewButton = reviewButtonBase.cloneNode(true);
                reviewButton.innerHTML = "Review";
                actionsCell.appendChild(reviewButton);
                row.appendChild(actionsCell);
            }
            body.appendChild(row);
        }
        record_num += 1
    }
    table.appendChild(body);
    return table
}

function updateFlashcardTables(data) {
    const questionTable = document.getElementById("flashcard-question-table");
    const tables = {}

    if (questionTable) {
        var question = buildReviewTable(data["question"], questionTable);
    } else {
        var question = buildReviewTable(data["question"]);
    }
    question.id = "flashcard-question-table";
    question.className = "table table-hover";
    tables["question"] = question.outerHTML;

    const matchesTable = document.getElementById("flashcard-matches-table");
    
    if (Object.keys(data["matches"]).length === 0) {
        
    } else if (matchesTable) {
        var matches = buildReviewTable(data["matches"], matchesTable);
    } else {
        var matches = buildReviewTable(data["matches"]);
    }

    try {
        matches.id = "flashcard-matches-table";
        matches.className = "table table-hover";
        tables["matches"] = matches.outerHTML;
    } catch {

    }

    return Promise.resolve(tables)
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

            const linkButton = linkButtonBase.cloneNode(true); 

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

                linkButton.value = "unlink";
                linkButton.innerHTML = "Unlink";
                if (table.id == "flashcard-question-table") {
                    actionsCell.appendChild(linkButton);
                } 
            }
            else {
                row.id = `collapse-${table.id}-tr-${record_num}`

                if (row_data["year"].match("-|,")) {
                    accordionDiv.appendChild(expandButton);
                    actionsCell.appendChild(accordionDiv);
                }
                
                linkButton.value = "link";
                linkButton.innerHTML = "Link";
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

// Store link logic should be updated on search page because
// the links should be ephemeral and should update as unlink and link
// are clicked within a modal. Changes should be committed immediately
// on clicking confirm changes. 
function storeLink(event) {
    const button = event.target;

    const matchesTable = document.getElementById("flashcard-matches-table"); 
    const matchRow = button.closest("tr");

    const questionTable = document.getElementById("flashcard-question-table");
    const baseRow = questionTable.getElementsByTagName("tr")[1];

    const baseRecord = rowToJSON(baseRow);
    const matchRecord = rowToJSON(matchRow)

    const linkType = button.value

    const linkDetails = {
        "link_type": linkType,
        "base_question_id": baseRecord.question_id,
        "match_question_id": matchRecord.question_id
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
    });

    const matchRows = document.querySelectorAll(`tr[id*="${matchRow.id}"]`);
    for (let i = 0; i < matchRows.length; i++) {
        let row = matchRows[i];
        row = document.getElementById(row.id);
        const button = row.getElementsByClassName("btn");
        if (linkType == "link") {
            questionTable.getElementsByTagName("tbody")[0].appendChild(row);
            if (button.length > 0) {
                button[0].value = "unlink";
                button[0].innerHTML = "Unlink";
            }
        } else if (linkType == "unlink") {
            const tbody = matchesTable.getElementsByTagName("tbody")[0]
           tbody.insertBefore(row, tbody.firstChild);
            if (button.length > 0) {
                button[0].value = "link";
                button[0].innerHTML = "Link";
            }
        }
    };
}

export {
    buildTable,
    updateTable,
    getQuestionData,
    buildSearchTable,
    rowToJSON,
    updateFlashcardTables,
    storeLink,
    buildReviewTable
}