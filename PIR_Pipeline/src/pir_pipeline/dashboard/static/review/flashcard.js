import { updateFlashcardTables, rowToJSON } from "../utilities.js";

document.addEventListener("DOMContentLoaded", buildFlashcardPage())

function buildFlashcardPage() {
    const body = sessionStorage.getItem("flashcardData");
    const bodyJson = JSON.parse(body);

    const reviewTypeInput = document.getElementById("review-type-input");
    reviewTypeInput.value = bodyJson["review-type"];
    
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
            "base_uqid": baseRecord.uqid,
            "match_question_id": null,
            "match_uqid": null
        }

        const payload = {
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
        value = "next";
    }
    formData.append(name, value);

    await fetch("/review/flashcard", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

function storeLink(event) {
    const button = event.target;
    const matchRow = button.closest("tr");
    const baseRow = document.getElementById("flashcard-question-table").getElementsByTagName("tr")[1];
    const baseRecord = rowToJSON(baseRow);
    const matchRecord = rowToJSON(matchRow)

    const linkDetails = {
        "link_type": button.value,
        "base_question_id": baseRecord.question_id,
        "base_uqid": baseRecord.uqid,
        "match_question_id": matchRecord.question_id,
        "match_uqid": matchRecord.uqid
    }

    const payload = {
        "action": "build",
        "data": linkDetails
    }

    fetch("/review/link", {
        "method": "POST",
        "headers": {
            "Content-type": "application/json"
        },
        "body": JSON.stringify(payload)
    })
}

document.storeLink = storeLink;
document.flashcardAction = flashcardAction;