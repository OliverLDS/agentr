.str_width <- function(x, url_length = 23L) {
  url_pattern <- "(https?://[^[:space:]]+)"
  m <- gregexpr(url_pattern, x, perl = TRUE)[[1]]
  n_urls <- if (m[1] == -1L) 0L else length(m)
  x_no_urls <- gsub(url_pattern, "", x, perl = TRUE)
  
  chars <- strsplit(x_no_urls, "")[[1]]
  base_count <- sum(ifelse(nchar(chars, type = "width") > 1, 2L, 1L))
  base_count + n_urls * url_length
}
  
.x_build_oauth1 <- function(api_key, api_secret, access_token, access_secret) {
  
  if (api_key == "" || api_secret == "" || access_token == "" || access_secret == "") {
    stop("Missing one or more X API credentials in environment variables.", call. = FALSE)
  }

  app <- httr::oauth_app("x", key = api_key, secret = api_secret)

  httr::sign_oauth1.0(
    app = app,
    token = access_token,
    token_secret = access_secret
  )
}

#' @export
x_get_me <- function(oauth1) {

  resp <- httr::GET(
    url   = "https://api.x.com/2/users/me",
    oauth1
  )
  httr::stop_for_status(resp)
  out <- httr::content(resp, as = "parsed", encoding = "UTF-8")

  if (is.null(out$data$id)) {
    stop("Could not get user id from /2/users/me response.", call. = FALSE)
  }

  out$data  # returns a list with id, name, username
}

#' @export
x_get_my_timeline <- function( # It will cost retrieving quota
  oauth1, 
  max_results      = 100,
  pagination_token = NULL,
  tweet_fields     = c("created_at", "public_metrics", "text", "lang")
) { 
  me   <- x_get_me(oauth1)
  uid  <- me$id

  base_url <- paste0("https://api.x.com/2/users/", uid, "/tweets")

  query <- list(
    max_results  = max_results,
    "tweet.fields" = paste(tweet_fields, collapse = ",")
  )
  if (!is.null(pagination_token)) {
    query$pagination_token <- pagination_token
  }

  resp <- httr::GET(
    url   = base_url,
    oauth1,
    query = query
  )
  httr::stop_for_status(resp)
  out <- httr::content(resp, as = "parsed", encoding = "UTF-8")
  out
}

#' @export
x_post_tweet <- function(text, oauth1, reply_to_tweet_id = NULL) {
  if (!is.character(text) || length(text) != 1L) {
    stop("`text` must be a single character string.", call. = FALSE)
  }
  
  if (.str_width(text) > 280) stop(sprintf('Exceeding text limit by %s.', .str_width(text) - 280))

  url  <- "https://api.x.com/2/tweets"

  body <- list(text = text)

  if (!is.null(reply_to_tweet_id)) {
    body$reply <- list(in_reply_to_tweet_id = as.character(reply_to_tweet_id))
  }

  resp <- httr::POST(
    url    = url,
    oauth1,
    body   = body,
    encode = "json"
  )

  # Don't stop immediately; inspect the body first
  txt <- httr::content(resp, as = "text", encoding = "UTF-8")

  if (httr::http_error(resp)) {
    cat("Status code:", httr::status_code(resp), "\n")
    cat("Raw body:\n", txt, "\n")
    stop("X API request failed. See status and raw body above.", call. = FALSE)
  }

  jsonlite::fromJSON(txt, simplifyVector = TRUE)
}

.x_upload_media <- function(oauth1, filepath) {

  url <- "https://upload.twitter.com/1.1/media/upload.json"

  resp <- httr::POST(
    url,
    oauth1,
    body = list(media = httr::upload_file(filepath))
  )

  httr::stop_for_status(resp)

  httr::content(resp, as = "parsed", encoding = "UTF-8")$media_id_string
}

#' @export
x_post_tweet_with_image <- function(text, image_path, oauth1) {
  media_id <- .x_upload_media(oauth1, image_path)
  
  if (!is.character(text) || length(text) != 1L) {
    stop("`text` must be a single character string.", call. = FALSE)
  }
  
  if (.str_width(text) > 280) stop('Exceeding text limit.')

  url <- "https://api.x.com/2/tweets"

  body <- list(
    text = text,
    media = list(
      media_ids = list(media_id)
    )
  )

  resp <- httr::POST(
    url,
    oauth1,
    body = body,
    encode = "json"
  )

  txt <- httr::content(resp, as = "text", encoding = "UTF-8")

  if (httr::http_error(resp)) {
    cat("Status:", httr::status_code(resp), "\n")
    cat("Raw body:\n", txt, "\n")
    stop("Tweet with image failed.", call. = FALSE)
  }

  jsonlite::fromJSON(txt)
}