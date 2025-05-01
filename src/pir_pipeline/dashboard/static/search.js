import { updateTable, rowToJSON } from "./utilities.js";
import { updateFlashcardTables, flashcardAction } from "./review.js";

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

async function buildFlashcardPage(e) {
    e.preventDefault();
    const element = e.target;
    const reviewType = document.getElementById("type-select").value.toLowerCase();

    const row = element.closest('tr');
    const rowRecord = rowToJSON(row);

    rowRecord["review-type"] = reviewType;
    
    await fetch("/search/flashcard")
        .then(response => response.text())
        .then(html => document.writeln(html))

    document.getElementById("review-type-input").value = reviewType;

    await fetch("/search/data", { "method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(rowRecord) })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

document.buildFlashcardPage = buildFlashcardPage;
document.flashcardAction = flashcardAction;