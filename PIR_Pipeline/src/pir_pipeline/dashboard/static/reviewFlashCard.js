import { storeLink, buildSearchTable } from "./utilities.js"

function buildFlashcardPage(e) {
    const element = e.target;
    const reviewType = element.textContent.trim().toLowerCase();
    window.location.assign(`/review/flashcard?review_type=${reviewType}`);
}

window.addEventListener("load", async (e) => {
    const current_page = document.URL;
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
    // .then(data => console.log(data))
    .then(data => {
        let questionTable = document.getElementById("flashcard-question-table");
        buildSearchTable(data["question"], questionTable);
        let matchesTable = document.getElementById("flashcard-matches-table");
        buildSearchTable(data["matches"], matchesTable);
    })
})

document.storeLink = storeLink;
document.buildFlashcardPage = buildFlashcardPage;