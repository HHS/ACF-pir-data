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
    table.innerHTML = '';
    let header = data[0];
    let head = document.createElement("thead");
    let headerRow = document.createElement("tr");
    head.appendChild(headerRow)
    for (let i = 0; i < header.length; i++) {
        const column = document.createElement("th");
        column.innerHTML = header[i];
        headerRow.appendChild(column);
    }
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
            const reviewType = document.getElementById("review-type").value
            const divID = table.id + "-div-" + i;
            const trID = table.id + "-tr-" + i;
            const tdID = table.id + "-td-" + i;
            row.className = "accordion-toggle cursor-pointer";
            row.setAttribute("data-bs-toggle", "collapse");
            row.setAttribute("data-bs-target", `#collapse-${trID}`);
            row.setAttribute("onclick", `getQuestionData(event, '${reviewType}')`)

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

        body.appendChild(row);
        if (table.id == "review-results-table") {
            body.appendChild(tr);
        }
    }

    table.appendChild(body);
}

function getQuestionData(event, reviewType) {
    const row = event.srcElement.parentElement;
    const tr = document.getElementById(row.getAttribute("data-bs-target").replace("#", ""));
    const div = document.getElementById(tr.id.replace("-tr-", "-div-"));

    // Exit if the target div already contains a table (i.e. matches have been found once).
    let table = div.getElementsByTagName("table");
    if (table.length > 0) {
        return
    }

    const cells = row.getElementsByTagName("td");
    let record = {}
    for (let i = 0; i < cells.length; i++) {
        const cell = cells[i]; 
        record[cell.getAttribute("name")] = cell.innerHTML;
    }
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
    table.className = "table table-hover";
    div.setAttribute("style", "width: 100%");
    div.appendChild(table);
    buildTable(data, table);
}

export {
    getColumns,
    buildDropdown,
    buildTable,
    updateTable,
    getQuestionData
}