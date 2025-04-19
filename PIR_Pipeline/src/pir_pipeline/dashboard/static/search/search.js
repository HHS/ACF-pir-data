import { updateTable, rowToJSON } from "../utilities.js";

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

    sessionStorage.setItem('flashcardData', JSON.stringify(rowRecord));
    window.location.href = "/search/flashcard";
}

document.getFlashcardData = getFlashcardData;