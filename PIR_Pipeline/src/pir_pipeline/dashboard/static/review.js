import { updateTable, getQuestionData } from "./utilities.js"

const reviewForm = document.getElementById("review-form");
reviewForm.addEventListener("change", async (e) => {
    e.preventDefault();
    const faux_event = new Event("submit");
    reviewForm.dispatchEvent(faux_event);
    updateTable(faux_event);
})

document.getQuestionData = getQuestionData;