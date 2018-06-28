#' Get US Palmer Drought Severity Index Data
#'
#' If the package already has the most current version of the data, you can
#' simply load the \code{pdsi} data set using \code{data(pdsi)}
#'
#' @param url name of current NCDC Palmer Drought Severity Index file
#'  located at \url{https://www1.ncdc.noaa.gov/pub/data/cirs/climdiv/}
#'  (e.g., file in June 2018 is 'climdiv-pdsidv-v1.0.0-20180604')
#' @param update logical (default \code{FALSE}); update current PDSI data
#'  associated with package?
#' @examples
#' \dontrun{
#' # File name changes with each NCDC monthly update, so modify accordingly
#' get_pdsi("climdiv-pdsidv-v1.0.0-20180604")
#' }
#' @export

pdsi_get <- function(url = "climdiv-pdsidv-v1.0.0-20180604", update = FALSE){
  base_url <- "https://www1.ncdc.noaa.gov/pub/data/cirs/climdiv/"
  url <- paste0(base_url, url)
  pdsi <- suppressMessages(
    readr::read_fwf(url,
                    readr::fwf_widths(c(4, 2, 4, rep(7, 12)),
                                      c("climdiv", "el", "year", 1:12)),
                    na = "-99.99"))
  pdsi <- dplyr::select(pdsi, -2) %>%
    tidyr::gather(key = "month", value = "pdsi", -.data$climdiv, -.data$year) %>%
    mutate(month = as.integer(.data$month)) %>%
    arrange(.data$climdiv, .data$year, .data$month) %>%
    filter(!is.na(.data$pdsi))
  if (update) saveRDS(pdsi, file = file.path(system.file("extdata", package = "pdsi"), "pdsi.rds"))
  pdsi
}
