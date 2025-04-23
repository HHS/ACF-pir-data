function initializeFlashcards(e) {
    const element = e.target;
    const reviewType = element.getAttribute("value");

    const body = {
        "for": "flashcard",
        "review-type": reviewType
    };


    sessionStorage.setItem("flashcardData", JSON.stringify(body));
    window.location.href = "/review/flashcard";
}


document.initializeFlashcards = initializeFlashcards;