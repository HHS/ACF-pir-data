import { updateTable, rowToJSON, updateFlashcardTables } from "../utilities.js";

const searchForm = document.getElementById("search-form")
searchForm.addEventListener("submit", async (e) => {
    // Flash an error if keyword is not provided
    if (!document.getElementById("keyword-search").value) {
        let data = {
            "error": "Missing keyword"
        }
        fetch("/search", {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(data)})
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

function getFlashcardData(e) {
    e.preventDefault();
    const element = e.target;

    const row = element.closest('tr');
    const rowRecord = rowToJSON(row);

    document.getElementById("search-modal").setAttribute("open", "true");
    document.getElementById("search-modal").removeAttribute("hidden");
    
    fetch("/search/data", { "method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(rowRecord)})
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

document.getFlashcardData = getFlashcardData;