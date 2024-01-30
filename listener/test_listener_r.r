# Define the output file path
output_file_path <- "C:/OHS-Project-1/watcher_obj/R_output/file.txt"  



cat("Task completed. Check", output_file_path, "for the output.\n")


# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)

# Check if there are any arguments
if (length(args) > 0) {
  # Extract the file path from the arguments
  file_path <- args[1]  # Assuming the file path is the first argument
  
  # Your script logic here, using the 'file_path' variable
  print_statement = paste("Received file path:", file_path)
  # Print "Hello, world!" to the text file
  cat(print_statement, file = output_file_path)
  
} else {

  cat("No command-line arguments provided.", file = output_file_path)

}