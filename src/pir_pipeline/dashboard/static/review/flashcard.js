import { updateFlashcardTables, rowToJSON, storeLink, buildTable, expandContractRow } from "../utilities.js";

// Run buildFlashcardPage when the page is loaded
document.addEventListener("DOMContentLoaded", buildFlashcardPage())

/**
 * Populates the flashcard page with content
 */
function buildFlashcardPage() {
    // Get flashcard data from session and remove
    let body = sessionStorage.getItem("flashcardData");
    sessionStorage.removeItem("flashcardData");

    // If there is no body, then the page is being loaded for the first tiem
    if (body === null) {
        body = {
            "for": "flashcard"
        };
        body = JSON.stringify(body);
    }

    // Make a request to get the flashcard data
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

/**
 * Stores linking/unlinking/and confirming actions as the user interacts with the application
 * 
 * @param {*} e - The event that triggered the flashcardAction function.
 */
async function flashcardAction(e) {
    e.preventDefault();

    // Get the form data
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

        // Add the confirm action to the dictionary of linking actions
        await fetch("/review/link", {
            "method": "POST",
            "headers": {
                "Content-type": "application/json"
            },
            "body": JSON.stringify(payload)
        })

        // Perform all linking actions to this points
        payload = {
            "action": "store",
            "html": questionTable.outerHTML
        }

        await fetch("/review/link", {
            "method": "POST",
            "headers": {
                "Content-type": "application/json"
            },
            "body": JSON.stringify(payload)
        })

        // Move to the next question
        value = "next";
    }

    // Get the data for the next (previous) question and update the tables
    formData.append(name, value);

    await fetch("/review/flashcard", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => updateFlashcardTables(data))
}

// Listen for submissions on the search form embedded in the review page
const searchForm = document.getElementById("search-form")

searchForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    // Flash an error if there is no search term
    if (!document.getElementById("keyword-search").value) {
        return;
    };

    // Otherwise get the form data
    const form = e.target;
    const formData = new FormData(form);
    const table = document.getElementById("flashcard-matches-table");

    // Get search results for the form data and replace the matches table
    fetch("/search", { "method": "POST", "body": formData })
        .then(response => response.json())
        .then(data => buildTable(data, table))
})

document.storeLink = storeLink;
document.flashcardAction = flashcardAction;
document.expandContractRow = expandContractRow;