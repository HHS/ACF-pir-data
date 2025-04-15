import { updateFlashcardTables } from "../review.js";

document.addEventListener("DOMContentLoaded", buildFlashcardPage())

async function buildFlashcardPage() {
    const rowRecord = sessionStorage.getItem("flashcardData");
    
    await fetch("/search/data", { "method": "POST", "headers": {"Content-type": "application/json"}, "body": rowRecord })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

document.updateFlashcardTables = updateFlashcardTables;