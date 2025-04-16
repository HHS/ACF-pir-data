import { rowToJSON } from "../utilities.js";
import { updateFlashcardTables } from "../review.js";

document.addEventListener("DOMContentLoaded", buildFlashcardPage())

async function buildFlashcardPage() {
    const rowRecord = sessionStorage.getItem("flashcardData");
    const rowRecordJson = JSON.parse(rowRecord);

    const reviewTypeInput = document.getElementById("review-type-input");
    reviewTypeInput.value = rowRecordJson["review-type"];
    
    await fetch("/search/data", { "method": "POST", "headers": {"Content-type": "application/json"}, "body": rowRecord })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

async function flashcardAction(e) {
    e.preventDefault();

    let value = e.submitter.value;
        
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

    window.history.back()

}

document.updateFlashcardTables = updateFlashcardTables;
document.flashcardAction = flashcardAction;