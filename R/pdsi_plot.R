#' Generate interactive plot US Palmer Drought Severity Index Data
#'
#' For description of PDSI index and drought/wetness levels, see the README
#'  at \url{https://www1.ncdc.noaa.gov/pub/data/cirs/climdiv/drought-readme.txt}
#'
#' @param lat numeric scalar of position latitude (decimal degrees; WGS84)
#' @param lon numeric scalar of position longitude (decimal degrees; WGS84)
#' @param address character scalar of a street address or place name
#'  (e.g. "Mattamuskeet NWR" or "135 Phoenix Rd, Athens, GA"); overrides
#'  \code{lat} and \code{lon} if specified. See example
#' @param nyrs numeric (default = 10); how many years before present would
#'  you like the initial graph to display?
#' @param fill one of NULL, "RdBu" (default), "BrBG", or "PuOr". Color scheme
#'  to use to indicate the different drought/wet bands behind the PDSI time
#'  series. NULL suppresses the background fill.
#' @examples
#' \dontrun{
#' pdsi_plot(34, -83)
#' pdsi_plot(address = "Alligator River NWR")
#' pdsi_plot(39, -77, fill = NULL)
#' }
#' @export

pdsi_plot <- function(lat = NULL, lon = NULL, address = NULL, nyrs = 10,
                      fill = c("RdBu", "BrBG", "PuOr")) {
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

  pdsi_avg <- filter(cd_pdsi, between(.data$year, 1901, 2000)) %>%
    pull(.data$pdsi) %>% mean() %>% round(2)

  title <- paste0("Palmer Drought Severity Index (",
                  min(cd_pdsi$year), " - ",
                  max(cd_pdsi$year), "): ",
                  cd_nm, " (", cd_st, ")")
  pdsi_ts <- zoo::zoo(cd_pdsi$pdsi, cd_pdsi$ymd)
  init_window <- as.character(c(max(cd_pdsi$ymd) - as.difftime(365.25 * nyrs, units = "days"),
                                max(cd_pdsi$ymd)))
  pdsi_dy <- dygraph(pdsi_ts, main = title)

  if (!is.null(fill)) {
    fill <- match.arg(fill)
    if (!requireNamespace("RColorBrewer", quietly = TRUE))
      utils::install.packages("RColorBrewer", quiet = TRUE)
    colors <- RColorBrewer::brewer.pal(11, fill)
    pdsi_dy <- pdsi_dy %>%
      dyShading(from = 4, to = max(7, max(cd_pdsi$pdsi)), axis = "y", color = colors[11]) %>%
      dyShading(from = 3, to = 4, axis = "y", color = colors[10]) %>%
      dyShading(from = 2, to = 3, axis = "y", color = colors[9]) %>%
      dyShading(from = 1, to = 2, axis = "y", color = colors[8]) %>%
      dyShading(from = 0.5, to = 1, axis = "y", color = colors[7]) %>%
      dyShading(from = -0.5, to = 0.5, axis = "y", color = colors[6]) %>%
      dyShading(from = -1, to = -0.5, axis = "y", color = colors[5]) %>%
      dyShading(from = -2, to = -1, axis = "y", color = colors[4]) %>%
      dyShading(from = -3, to = -2, axis = "y", color = colors[3]) %>%
      dyShading(from = -4, to = -3, axis = "y", color = colors[2]) %>%
      dyShading(from = min(-7, min(cd_pdsi$pdsi)), to = -4, axis = "y", color = colors[1])
  }

  pdsi_dy <- pdsi_dy %>%
    dyOptions(axisLineWidth = 2, connectSeparatedPoints = FALSE,
              axisLabelFontSize = 24, gridLineColor = "gray50") %>%
    dyAxis("y", labelWidth = 24,
           label = "DRY &larr; Palmer Drought Severity Index &rarr; WET") %>%
    dySeries("V1", label = "PDSI", color = "black", drawPoints = TRUE,
             strokeWidth = 2, pointSize = 2.5) %>%
    dyLimit(pdsi_avg, label = "Mean PDSI (1901-2000)", color = "gray30",
            strokePattern = "dashed") %>%
    dyLegend(show = "follow", width = 150) %>%
    dyRangeSelector(height = 24, strokeColor = "", dateWindow = init_window)
  pdsi_dy
}
