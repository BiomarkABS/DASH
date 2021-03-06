#' @title Read On-The-Ground .csv Data
#'
#' @description Import .csv delimited files containing on-the-ground (OTG) data collected using the
#' DASH protocol. This function only reads in one `otg_type` of data at a time.
#'
#' @inheritParams get_file_nms
#' @inheritParams get_otg_col_specs
#'
#' @import purrr dplyr
#' @importFrom readr read_csv
#' @importFrom magrittr %>%
#' @importFrom compare compare
#' @importFrom stringr str_split
#' @importFrom lubridate mdy
#' @export
#' @return a data frame containing data of \code{otg_type}

read_otg_csv = function(path = ".",
                        otg_type = c("surveyPoint_0.csv",
                                     "CU_1.csv",
                                     "Wood_2.csv",
                                     "Jam_3.csv",
                                     "Undercut_4.csv",
                                     "Discharge_5.csv",
                                     "DischargeMeasurements_6.csv")) {

  # files list of the otg_type
  file_list = get_file_nms(path) %>%
    dplyr::filter(file_nm == otg_type) %>%
    #dplyr::mutate(file_cnt = row_number()) %>%
    split(list(.$path_nm))

  # grab intended column specifications using get_otg_col_specs()
  otg_col_specs = get_otg_col_specs(otg_type)

  # map_df over file_list
  tmp_df = file_list %>%
    purrr::map_df(.id = "path_nm",
                  .f = function(x) {

                    cat(paste("Importing", otg_type, "file from", x$folder_nm, "survey folder.", "\n"))

                    # get column specifications from file
                    tmp_specs = readr::read_csv(paste0(path, x$path_nm), col_types = readr::cols()) %>%
                      readr::spec()

                    #####
                    # CHECK 1: check if tmp_specs match the expected from get_otg_col_specs()
                    # chk = identical(otg_col_specs, tmp_specs)
                    # a "looser" version of identical() to allow for differing attributes
                    chk = compare::compare(otg_col_specs, tmp_specs, allowAll = T)[[1]]
                    if(chk == FALSE) warning(paste("Column specifications in", otg_type, "file from", x$folder_nm, "survey folder do not match those defined in get_otg_col_specs().", "\n",
                                                   all.equal(otg_col_specs, tmp_specs), "\n"))

                    #####
                    # CHECK 2: check if column names match
                    chk = identical(names(otg_col_specs$cols), names(tmp_specs$cols))
                    if(chk == FALSE) cat(paste("Column names in", otg_type, "file from", x$folder_nm, "survey folder do not match the expected names defined in get_otg_col_specs(). Check file format. Continuing...", "\n"))

                    #####
                    # CHECK 3: check if number of columns match
                    chk = identical(length(otg_col_specs$cols), length(tmp_specs$cols))
                    if(chk == FALSE) stop(paste("Fatal Error: Number of columns in", otg_type, "file from", x$folder_nm, "survey folder is unexpected."))

                    # read in the single .csv file of otg_type
                    tmp = try(suppressWarnings(readr::read_csv(paste0(path, x$path_nm),
                                                               col_types = otg_col_specs)))

                    # change the format of Survey Date from character to date/time
                    if(otg_type == "surveyPoint_0.csv" & nrow(tmp) > 0) {
                      tmp = tmp %>%
                        mutate(`Survey Date` = stringr::str_split(`Survey Date`, " ", simplify = T)[,1],
                               `Survey Date` = lubridate::mdy(`Survey Date`),
                               `Survey Date` = lubridate::ymd_hms(paste(`Survey Date`, `Survey Time`)))
                    }

                    # extract the date portion for CreationDate and EditDate
                    if(nrow(tmp) > 0 & sum(c("CreationDate", "EditDate") %in% names(tmp)) > 0) {
                      tmp = tmp %>%
                        mutate(across(any_of(c("CreationDate", "EditDate")),
                                      ~ stringr::str_split(., " ", simplify = T)[,1])) %>%
                        mutate(across(any_of(c("CreationDate", "EditDate")),
                                      lubridate::mdy))
                    }

                    #####
                    # CHECK 4
                    if(chk == FALSE | class(tmp)[1] == "try-error") {
                      cat(paste("Problem reading in", otg_type, "file from", x$folder_nm, "survey. Returning NULL and moving on...", "\n"))
                      return(NULL)
                    } else if(nrow(tmp) == 0) {
                      cat(paste("The", otg_type, "file from", x$folder_nm, "survey contains zero records. Returning NULL and moving on...", "\n"))
                      return(NULL)
                    } else if(chk == TRUE) {
                      cat(paste("Success!", "\n"))
                      return(tmp)
                    }

                  })

  # DELETE ANY ROWS WHERE "GlobalID" is NA...
  tmp_df = tmp_df %>%
    dplyr::filter(!is.na(GlobalID))

  return(tmp_df)

} # end read_otg_csv()
