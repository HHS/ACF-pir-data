import { storeLink, buildTable } from "./utilities.js"

function buildFlashcardPage(e) {
    const element = e.target;
    const reviewType = element.textContent.trim().toLowerCase();
    window.location.assign(`/review/flashcard?review_type=${reviewType}`);
}

window.addEventListener("load", async (e) => {
    const current_page = document.URL;
    console.log("ran");
    if (current_page.search("flashcard") == -1) {
        return
    }

    const query = current_page.match("(?<=\\?).+")[0]
    const searchParams = new URLSearchParams(query);
    const reviewType = searchParams.get("review_type");
    console.log(reviewType);
    
    const body = {
        "for": "flashcard",
        "review-type": reviewType
    }
    const payload = { 
        "method": "POST", 
        "headers": { 
            "Content-type": "application/json"
        }, 
        "body": JSON.stringify(body) 
    }

    fetch("/review/data", payload)
    .then(response => response.json())
    .then(data => {
        let questionTable = document.getElementById("flashcard-question-table");
        console.log(data);
        buildTable(data["question"], questionTable);
        let matchesTable = document.getElementById("flashcard-matches-table");
        buildTable(data["matches"], matchesTable);
    })
})

document.storeLink = storeLink;
document.buildFlashcardPage = buildFlashcardPage;