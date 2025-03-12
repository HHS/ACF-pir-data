import { doKeywordSearch } from "./utilities.js";

const searchForm = document.getElementById("search-form")
searchForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    doKeywordSearch(e);
})