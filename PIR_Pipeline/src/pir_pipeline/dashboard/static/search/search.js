import { updateTable, rowToJSON } from "../utilities.js";
import { updateFlashcardTables, flashcardAction } from "../review.js";

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
    const reviewType = document.getElementById("type-select").value.toLowerCase();

    const row = element.closest('tr');
    const rowRecord = rowToJSON(row);

    rowRecord["review-type"] = reviewType;

    sessionStorage.setItem('flashcardData', JSON.stringify(rowRecord));
    window.location.href = "/search/flashcard";
}

document.flashcardAction = flashcardAction;
document.getFlashcardData = getFlashcardData;