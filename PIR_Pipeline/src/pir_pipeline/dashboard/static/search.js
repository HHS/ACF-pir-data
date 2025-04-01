import { updateTable, getColumns} from "./utilities.js";

const searchForm = document.getElementById("search-form")
searchForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    updateTable(e);
})

document.getColumns = getColumns;