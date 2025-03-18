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