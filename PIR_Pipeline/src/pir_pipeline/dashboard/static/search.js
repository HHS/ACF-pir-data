import { updateTable, getColumns} from "./utilities.js";

const searchForm = document.getElementById("search-form")
searchForm.addEventListener("submit", async (e) => {
    if (!document.getElementById("keyword-search").value) {
        let data = {
            "error": "Missing keyword"
        }
        fetch("/search", {"method": "POST", "headers": {"Content-type": "application/json"}, "body": JSON.stringify(data)})
        return;
    }
    e.preventDefault();
    updateTable(e);
})

document.getColumns = getColumns;