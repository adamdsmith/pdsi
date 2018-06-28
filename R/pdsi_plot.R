#' Generate interactive plot US Palmer Drought Severity Index Data
#'
#' @param lat numeric scalar of position latitude (decimal degrees; WGS84)
#' @param lon numeric scalar of position longitude (decimal degrees; WGS84)
#' @param address character scalar of a street address or place name
#'  (e.g. "Mattamuskeet NWR" or "135 Phoenix Rd, Athens, GA"); overrides
#'  \code{lat} and \code{lon} if specified. See example
#' @param nyrs numeric (default = 10); how many years before present would
#'  you like the initial graph to display?
#' @examples
#' \dontrun{
#' pdsi_plot(34, -83)
#' pdsi_plot(address = "Alligator River NWR")
#' }
#' @export

pdsi_plot <- function(lat = NULL, lon = NULL, address = NULL, nyrs = 10) {
  if (is.null(c(lat, lon, address)))
    stop("At least one of lat/lon or address must be specified.")
  if (!is.null(address)) {
    if (!requireNamespace("ggmap", quietly = TRUE))
      utils::install.packages("ggmap", quiet = TRUE)
    if (!is.character(address))
      stop('`address` must be a character scalar of a street address ',
           'or place name (e.g. "Mattamuskeet NWR" or "135 Phoenix Rd, Athens, GA")')
    ll = tryCatch(ll <- suppressMessages(ggmap::geocode(address)),
                  error = function(e) return(e),
                  warning = function(w) stop(w))
    lat <- ll$lat; lon <- ll$lon
  }
  pt <- st_point(c(lon, lat)) %>%
    st_sfc(crs = 4326)
  cd <- st_read(system.file("extdata/conus_climdiv.gpkg", package = "pdsi"),
                stringsAsFactors = FALSE,
                quiet = TRUE)
  pdsi <- readRDS(system.file("extdata/pdsi.rds", package = "pdsi"))
  cd_pt <- suppressMessages(cd[as.numeric(st_within(pt, cd)),])
  cd_st <- pull(cd_pt, .data$st_abbr)
  cd_nm <- pull(cd_pt, .data$cd_name)
  climdiv_pt <- pull(cd_pt, .data$climdiv) %>% as.character()
  if (nchar(climdiv_pt) < 4) climdiv_pt <- paste0(0, climdiv_pt)
  cd_pdsi <- pdsi %>%
    filter(.data$climdiv == climdiv_pt) %>%
    mutate(ymd = lubridate::ymd(paste(.data$year, .data$month, 1, sep = "-")))

  title <- paste0("Palmer Drought Severity Index (",
                  min(cd_pdsi$year), " - ",
                  max(cd_pdsi$year), ") <br>",
                  cd_st, ": ", cd_nm)
  pdsi_ts <- zoo::zoo(cd_pdsi$pdsi, cd_pdsi$ymd)
  init_window <- as.character(c(max(cd_pdsi$ymd) - as.difftime(365.25 * nyrs, units = "days"),
                                max(cd_pdsi$ymd)))
  pdsi_dy <- dygraph(pdsi_ts, main = title) %>%
    dyOptions(axisLineWidth = 2, connectSeparatedPoints = FALSE,
              axisLabelFontSize = 30,
              strokeWidth = 1.5) %>%
    dyAxis("y", label = "Palmer Drought Severity Index", labelWidth = 30) %>%
    dySeries("V1", label = "PDSI") %>%
    dyLegend(show = "follow", width = 150) %>%
    dyRangeSelector(height = 20, strokeColor = "", dateWindow = init_window)
  pdsi_dy
}
