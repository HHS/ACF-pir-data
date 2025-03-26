function getColumns(event) {
    const dropdown = event.srcElement;
    let data = {
        "element": dropdown.id,
        "value": dropdown.value
    };
    fetch(document.URL, {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(data)})
    .then(response => response.json())
    .then(options => buildDropdown(options));
}

function buildDropdown(options) {
    const dropdown = document.getElementById("column-select");
    dropdown.innerHTML = '';

    for (let i = 0; i < options.length; i++) {
        const option = document.createElement("option");
        option.value = options[i];
        option.text = options[i];
        dropdown.appendChild(option);
    }
}

function updateTable(event) {
    // Get the form data
    const form = event.srcElement;
    const formData = new FormData(form);

    // Get the table to be updated
    const tables = document.getElementsByTagName("table");
    const table = tables[0];

    fetch(document.URL, {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => buildTable(data, table));
}

function buildTable(data, table) {
    // Constant buttons
    const expandButtonBase = document.createElement("button");
    expandButtonBase.className = "btn btn-primary";
    expandButtonBase.setAttribute("type", "button");
    expandButtonBase.setAttribute("data-bs-toggle", "collapse");
    expandButtonBase.setAttribute("aria-expanded", "false");

    const linkButtonBase = document.createElement("button");
    linkButtonBase.className = "btn btn-primary";
    linkButtonBase.setAttribute("onclick", "storeLink(event)");

    // Other constants
    const reviewType = document.getElementById("review-type").value

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
            expandButton.innerHTML = "Expand";
            expandButton.setAttribute("data-bs-target", `#collapse-${trID}`);
            expandButton.setAttribute("aria-controls", `collapse-${trID}`);
            expandButton.setAttribute("onclick", `getQuestionData(event, '${reviewType}')`);
            const actionsCell = document.createElement("td");
            actionsCell.appendChild(expandButton);
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
    const row = event.srcElement.parentElement.parentElement;
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
    
    fetch("/match", {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(payload)})
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

function storeLink(event) {
    const button = event.srcElement;
    const matchRow = button.closest("tr");
    const matchID = matchRow.closest("table").closest("tr").id;
    const baseRow = document.querySelector(`button[aria-controls="${matchID}"`).closest("tr");
    let baseRecord = rowToJSON(baseRow);
    let matchRecord = rowToJSON(matchRow);
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
    
    fetch("/link", {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(payload)})
}

export {
    getColumns,
    buildDropdown,
    buildTable,
    updateTable,
    getQuestionData,
    storeLink
}