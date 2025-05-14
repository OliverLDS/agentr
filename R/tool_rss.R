#' Fetch and parse RSS feed for economic news
#' @export
tool_fetch_rss <- function(url = "https://www.federalreserve.gov/feeds/press_all.xml") {
  xml <- xml2::read_xml(url)
  items <- xml2::xml_find_all(xml, "//item")
  titles <- xml2::xml_text(xml2::xml_find_all(items, "title"))
  links  <- xml2::xml_text(xml2::xml_find_all(items, "link"))
  dates  <- xml2::xml_text(xml2::xml_find_all(items, "pubDate"))
  data.frame(title = titles, link = links, date = dates, stringsAsFactors = FALSE)
}
