# collapseConsecutive <- function(string) {
#   split_string <- strsplit(string, ",")[[1]]
#   split_string <- as.numeric(split_string)
#   split_string <- rev(sort(split_string))
#   
#   appendString <- function() {
# 
#     if (exists("new_string")) {
#       print(new_string)
#       if (new_range != "-") {
#         new_string <- paste(new_string, new_range, curr_num, sep = ", ")
#       } else {
#         new_string <- paste(new_string, curr_num, sep = ", ")
#       }
#     } else {
#       if (new_range != "-") {
#         new_string <- new_range
#       } else {
#         new_string <- curr_num
#       }
#     }
#     return(new_string)
#   }
# 
#   while (length(split_string) > 0) {
#     if (exists("curr_num")) {
#       prev_num <- curr_num
#     }
#     curr_num <- pop(split_string)
#     if (exists("prev_num")) {
#       if (curr_num - 1 == prev_num) {
#         max_num <- as.character(curr_num)
#       } else {
#         new_range <- paste(min_num, max_num, sep = "-")
#         new_string <- appendString()
#         rm(min_num, max_num, new_range, prev_num)
#       }
#     } else {
#       min_num <- as.character(curr_num)
#     }
#     if (length(split_string) == 1) {
#       new_range <- paste(min_num, max_num, sep = "-")
#       new_string <- appendString()
#     }
#     print(curr_num)
#   }
#   return(new_string)
# }
# 
# collapseConsecutive(temp)
