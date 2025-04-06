import { storeLink, buildSearchTable } from "./utilities.js"

function buildFlashcardPage(e) {
    const element = e.target;
    initializeFlashcards(element);
}

function initializeFlashcards(elem) {
    const reviewType = elem.getAttribute("value");
    
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

    fetch("/review/data", payload)
    .then(response => response.json())
    .then(async (data) => {
        await fetch("/review/init-flashcard")
        .then(response => response.text())
        .then(html => document.writeln(html))

        document.getElementById("review-type-input").value = reviewType;
        await updateFlashcardTables(data)
    })
}

function flashcardAction(e) {
    e.preventDefault();
    const form = e.target;
    const formData = new FormData(form);
    formData.append(e.submitter.name, e.submitter.value);

    fetch("/review/flashcard", {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => updateFlashcardTables(data))
}

function updateFlashcardTables(data) {
    const questionTable = document.getElementById("flashcard-question-table");
    if (questionTable) {
        var question = buildSearchTable(data["question"], questionTable);
    } else {
        var question = buildSearchTable(data["question"]);
    }
    question.id = "flashcard-question-table";
    question.className = "table table-hover";

    const matchesTable = document.getElementById("flashcard-matches-table");
    if (matchesTable) {
        var matches = buildSearchTable(data["matches"], matchesTable);
    } else {
        var matches = buildSearchTable(data["matches"]);
    }
    matches.id = "flashcard-matches-table";
    matches.className = "table table-hover";

    const tables = {
        "question": question.outerHTML,
        "matches": matches.outerHTML
    }

    return Promise.resolve(tables)
}

document.storeLink = storeLink;
document.buildFlashcardPage = buildFlashcardPage;
document.flashcardAction = flashcardAction;