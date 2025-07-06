#' Send an Email Using SMTP via emayili
#'
#' Sends an email using the Gmail SMTP server with the \pkg{emayili} package.
#' The message must include a recipient, subject, and body. Authentication details
#' (email and app password) are provided via the \code{config} list.
#'
#' @param input A named list containing the message:
#' \describe{
#'   \item{\code{to}}{Recipient email address.}
#'   \item{\code{subject}}{Subject line of the email.}
#'   \item{\code{body}}{Body text of the email.}
#' }
#' @param config A named list of email credentials, typically set via \code{tool_set_config("email")}, containing:
#' \describe{
#'   \item{\code{from}}{Sender email address (must match Gmail credentials).}
#'   \item{\code{password}}{App-specific password for SMTP authentication.}
#' }
#'
#' @return Logical \code{TRUE} if the email is successfully sent.
#' @examples
#' \dontrun{
#' config <- tool_set_config("email")
#' send_email(
#'   input = list(
#'     to = "friend@example.com",
#'     subject = "Hello from R!",
#'     body = "This is a test email sent by XAgent."
#'   ),
#'   config = config
#' )
#' }
#'
#' @export
send_email <- function(input, config) {
  if (any(c("to", "subject", "body") %in% names(input)) == FALSE)
    stop("input must include 'to', 'subject', and 'body'")

  email <- emayili::envelope() |>
    emayili::from(config$from) |>
    emayili::to(input$to) |>
    emayili::subject(input$subject) |>
    emayili::text(input$body)

  smtp <- emayili::server(
    host = "smtp.gmail.com",
    port = 587,
    username = config$from,
    password = config$password
  )

  smtp(email)
  return(TRUE)
}

# input <- list(
#   to = "olee7149@gmail.com",
#   subject = "Weekly Summary",
#   body = "Hi, here's your update!"
# )
# send_email(input)
