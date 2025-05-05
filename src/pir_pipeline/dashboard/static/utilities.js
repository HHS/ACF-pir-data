// Logic adapted from Gemini
/**
 * Return the correct svg image for a linking element
 * 
 * @param {*} button 
 */
function getLinkingSVG(button) {
    if (button.value == "unlink") {
        fetch('/static/images/Close--large.svg')
            .then(response => response.text())
            .then(svgData => {
                const parser = new DOMParser();
                const svgDOM = parser.parseFromString(svgData, 'image/svg+xml');
                const svgElement = svgDOM.documentElement;
                button.appendChild(svgElement);
            })
    } else if (button.value == "link") {
        fetch('/static/images/Add--large.svg')
            .then(response => response.text())
            .then(svgData => {
                const parser = new DOMParser();
                const svgDOM = parser.parseFromString(svgData, 'image/svg+xml');
                const svgElement = svgDOM.documentElement;
                button.appendChild(svgElement);
            })
    } else if (button.value == "review") {
        fetch('/static/images/Edit.svg')
            .then(response => response.text())
            .then(svgData => {
                const parser = new DOMParser();
                const svgDOM = parser.parseFromString(svgData, 'image/svg+xml');
                const svgElement = svgDOM.documentElement;
                button.appendChild(svgElement);
            })
    }
}

/**
 * Update the table related to the present event
 * 
 * @param {*} event The event triggering the table update
 */
function updateTable(event) {
    // Get the form data
    const form = event.srcElement;
    const formData = new FormData(form);

    // Get the table to be updated
    const tables = document.getElementsByTagName("table");
    const table = tables[0];

    // Make a post request to the current page
    fetch(document.URL, { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => {
            if (table.id.match("review")) {
                buildTable(data, table)
            } else {
                buildSearchTable(data, table)
            }
        });
}

/**
 * Populate the target table with the provided data
 * 
 * @param {*} data JSON formatted data to use to populate the table
 * @param {*} table The table to build/update
 * @returns An HTML table element
 */
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
    linkButtonBase.setAttribute("onclick", "storeLink(event)");

    // Set table header row
    table.innerHTML = '';

    let header = data[0]; // List of column names
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

    // Populating the table body
    let body = document.createElement("tbody");

    for (let i = 1; i < data.length; i++) {
        const row = document.createElement("tr");

        // Add data to the table
        let row_data = data[i]; // Table entry
        for (let key in row_data) {
            const cell = document.createElement("td");
            cell.innerHTML = row_data[key];
            cell.setAttribute("name", key);
            row.appendChild(cell);
        }

        body.appendChild(row);
    }

    table.appendChild(body);
    return table;
}

/**
 * Convert a table row to JSON
 * 
 * @param {*} row A table row to convert to JSON
 * @returns JSON object containing data from a table row
 */
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

/**
 * Build the search table
 * 
 * @param {*} data The data to use to build the search table
 * @param {*} table An HTML table to fill with content
 * @returns An HTML table element
 */
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
    reviewButtonBase.value = "review";

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

    // Build table body
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

            // If not the first row, this row should be hidden/collapsible
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
            // Otherwise, it is the header-row
            else {
                row.setAttribute("onclick", "expandContractRow(event)");

                if (row_data["year"].match(",|-")) {
                    accordionDiv.appendChild(expandButton);
                }

                actionsCell.appendChild(accordionDiv);

                const reviewButton = reviewButtonBase.cloneNode(true);
                getLinkingSVG(reviewButton);
                
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

/**
 * Update the flashcard tables
 * 
 * @param {*} data The data to use to update the table
 * @returns 
 */
function updateFlashcardTables(data) {
    // Update the main question table (the question being edited)
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

    // Update the matches table
    const matchesTable = document.getElementById("flashcard-matches-table");

    if (Object.keys(data["matches"]).length === 0) {
        // When no matches are found render a message
        try {
            matchesTable.innerHTML = "No suitable matches found. Try searching instead."
        } catch {

        }
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

/**
 * 
 * @param {*} data The data to use to populate the table
 * @param {*} table The table to update
 * @returns 
 */
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
    // linkButtonBase.className = "btn btn-primary";
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

            // If not the first row, this row should be hidden/collapsible
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
                getLinkingSVG(linkButton);
                if (table.id == "flashcard-question-table") {
                    actionsCell.appendChild(linkButton);
                }
            }
            // Otherwise, it is the header-row
            else {
                row.id = `collapse-${table.id}-tr-${record_num}`

                if (row_data["year"].match("-|,")) {
                    accordionDiv.appendChild(expandButton);
                    actionsCell.appendChild(accordionDiv);
                }

                linkButton.value = "link";
                getLinkingSVG(linkButton);
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

/**
 * Store linking actions made by the user within the session
 * 
 * @param {*} event The event that triggered storeLink
 */
function storeLink(event) {
    let button = event.target;
    if (button.tagName != "BUTTON") {
        button = button.closest("button");
    }

    // Get the records to be matched
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

    // Store the link
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

    // Move the row(s) involved in the match to the questionTable/matchesTable
    const matchRows = document.querySelectorAll(`tr[id*="${matchRow.id}"]`);

    for (let i = 0; i < matchRows.length; i++) {
        let row = matchRows[i];
        row = document.getElementById(row.id);

        if (row.className.match("accordion-collapse")) {
            row.className = row.className + " show";
        }

        let button = row.getElementsByTagName("svg");

        // Update the button image and move the row to the corresponding table
        if (linkType == "link") {
            // Add to the end of the questionTable if a link was made
            questionTable.getElementsByTagName("tbody")[0].appendChild(row);
            if (button.length > 0) {
                button = button[0].closest("button");
                button.value = "unlink";
                button.innerHTML = "";
                getLinkingSVG(button);
            }
        } else if (linkType == "unlink") {
            // Add to the top of the matchesTable if a link was broken
            const tbody = matchesTable.getElementsByTagName("tbody")[0]

            // The first row should be inserted at the top and all subsequent rows after it
            if (i == 0) {
                tbody.insertBefore(row, tbody.firstChild);
                var headerRow = row;
            } else {
                headerRow.after(row);
            }

            if (button.length > 0) {
                button = button[0].closest("button");
                button.value = "link";
                button.innerHTML = "";
                getLinkingSVG(button);
            }
        }
    };
}

/**
 * Expand or contract a row
 * 
 * @param {*} event Event that triggered expandContractRow 
 */
function expandContractRow(event) {
    var element = event.srcElement;
    if (element.tagName == "TD") {
        element = element.closest("tr");
    }
    const expandButton = element.getElementsByClassName("accordion-button");

    if (expandButton[0]) {
        expandButton[0].click()
    };
}

export {
    buildTable,
    updateTable,
    buildSearchTable,
    rowToJSON,
    updateFlashcardTables,
    storeLink,
    buildReviewTable,
    expandContractRow
}