import { storeLink, buildSearchTable } from "./utilities.js"

// Adapted from https://stackoverflow.com/questions/53777061/run-window-addeventlistenerload-only-once
const { href } = window.location;
const alreadyLoaded = JSON.parse(localStorage.loaded || '[]');

function buildFlashcardPage(e) {
    const element = e.target;
    const reviewType = element.textContent.trim().toLowerCase();
    window.location.assign(`/review/flashcard?review_type=${reviewType}`);
}

const once = {
    once: true
};

if (!alreadyLoaded.includes(href)) {
    window.addEventListener("load", async (e) => initializeFlashcards(e), once);
    localStorage.loaded = JSON.stringify(alreadyLoaded);
    console.log(alreadyLoaded)
    alreadyLoaded.push(href);
}

function initializeFlashcards(e) {
    const current_page = document.URL;
    if (current_page.search("flashcard") == -1) {
        return
    };

    const query = current_page.match("(?<=\\?).+")[0]
    const searchParams = new URLSearchParams(query);
    const reviewType = searchParams.get("review_type");
    
    const body = {
        "for": "flashcard",
        "review-type": reviewType
    };
    const payload = { 
        "method": "POST", 
        "headers": { 
            "Content-type": "application/json"
        }, 
        "body": JSON.stringify(body) 
    };

    fetch("/review/init-flashcard", payload)
    .then(response => response.json())
    .then(data => updateFlashcardTables(data));

    const reviewTypeInput = document.getElementById("review-type-input");
    reviewTypeInput.setAttribute("value", reviewType);
}

function flashcardAction(e) {
    const form = e.target;
    const formData = new FormData(form);
    formData.append(e.submitter.name, e.submitter.value);
    console.log(formData);

    fetch("/review/flashcard", {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => updateFlashcardTables(data))
}

function updateFlashcardTables(data) {
    const questionTable = document.getElementById("flashcard-question-table");
    buildSearchTable(data["question"], questionTable);
    const matchesTable = document.getElementById("flashcard-matches-table");
    buildSearchTable(data["matches"], matchesTable);
}

document.storeLink = storeLink;
document.buildFlashcardPage = buildFlashcardPage;
document.flashcardAction = flashcardAction;