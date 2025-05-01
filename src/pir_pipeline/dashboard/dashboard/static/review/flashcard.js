import { updateFlashcardTables, rowToJSON, storeLink, buildReviewTable } from "../utilities.js";

document.addEventListener("DOMContentLoaded", buildFlashcardPage())

function buildFlashcardPage() {
    let body = sessionStorage.getItem("flashcardData");
    sessionStorage.removeItem("flashcardData");
    const bodyJson = JSON.parse(body);

    if (body === null) {
        body = {
            "for": "flashcard"
        };
        body = JSON.stringify(body);
    }
    
    const payload = {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": body
    };

    fetch("/review/data", payload)
        .then(response => response.json())
        .then(data => updateFlashcardTables(data));
}

async function flashcardAction(e) {
    e.preventDefault();
    console.log(e)
    const form = e.target;
    const formData = new FormData(form);
    const name = e.submitter.name;
    let value = e.submitter.value;
    
    if (value == "confirm") {
        const questionTable = document.getElementById("flashcard-question-table");
        let baseRecord = rowToJSON(questionTable.getElementsByTagName("tr")[1]);
        const linkDetails = {
            "link_type": value,
            "base_question_id": baseRecord.question_id,
            "match_question_id": null
        }

        let payload = {
            "action": "build",
            "data": linkDetails
        }

        await fetch("/review/link", {
            "method": "POST",
            "headers": {
                "Content-type": "application/json"
            },
            "body": JSON.stringify(payload)
        })

        payload = {
            "action": "finalize"
        }

        await fetch("/review/link", {
            "method": "POST",
            "headers": {
                "Content-type": "application/json"
            },
            "body": JSON.stringify(payload)
        })

        value = "next";
    }
    formData.append(name, value);

    await fetch("/review/flashcard", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

const searchForm = document.getElementById("search-form")
searchForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (!document.getElementById("keyword-search").value) {
        return;
    };

    const form = e.target;
    const formData = new FormData(form);
    const table = document.getElementById("flashcard-matches-table");

    fetch("/search", {"method": "POST", "body": formData})
    .then(response => response.json())
    .then(data => buildReviewTable(data, table))
})

document.storeLink = storeLink;
document.flashcardAction = flashcardAction;