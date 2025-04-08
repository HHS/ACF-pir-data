import { buildSearchTable, rowToJSON } from "./utilities.js"

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
document.buildFlashcardPage = buildFlashcardPage;
document.flashcardAction = flashcardAction;