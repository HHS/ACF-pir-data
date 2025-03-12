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

function doKeywordSearch(event) {
    const form = event.srcElement;
    const formData = new FormData(form);

    fetch(document.URL, {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => buildTable(data));
}

function buildTable(data) {
    const table = document.getElementById("search-results-table");

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
        const row = document.createElement("tr")
        let row_data = data[i];
        for (let key in row_data) {
            const cell = document.createElement("td");
            cell.innerHTML = row_data[key];
            row.appendChild(cell);
            // console.log(row);
        }
        body.appendChild(row);
    }

    table.appendChild(body)
}

function getReviewTable(event) {
    const form = event.srcElement;
    const formData = new FormData(form);
    console.log(form.id);
    exit()

    fetch(document.URL, {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => buildTable(data));
}

export {
    getColumns,
    buildDropdown,
    buildTable,
    doKeywordSearch,
    getReviewTable
}