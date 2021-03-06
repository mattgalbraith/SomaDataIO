#' Mathematical Group Generics for ADAT Object
#'
#' This is the S3 group generic method to apply mathematical functions
#' to the RFU data of `soma_adat` objects.
#' The clinical meta data is *not* transformed and remains in
#' the returned object. Typical generic functions include:
#'   * `log()`
#'   * `abs()`
#'   * `sign()`
#'   * `floor()`
#'   * `sqrt()`
#'   * `exp()`
#'   * See [groupGeneric()] (\emph{Math}) for full listing
#' @name MathGenerics
#' @param x The `soma_adat` class object to perform the transformation.
#' @param ... Additional arguments passed to the various group generics
#' as appropriate.
#' @return A `soma_adat` object with the same dimensions of the input
#' object with the feature columns transformed by the specified generic.
#' @author Stu Field
#' @seealso [groupGeneric()]
#' @examples
#' example_data$seq.3343.1
#'
#' # log-transformation
#' a <- log(example_data)
#' a$seq.3343.1
#' b <- log10(example_data)
#' b$seq.3343.1
#' isTRUE(all.equal(b, log(example_data, base = 10)))
#'
#' # floor
#' c <- floor(example_data)
#' c$seq.3343.1
#'
#' # square-root
#' d <- sqrt(example_data)
#' d$seq.3343.1
#'
#' # rounding
#' e <- round(example_data)
#' e$seq.3343.1
#' @importFrom usethis ui_stop
#' @export
Math.soma_adat <- function(x, ...) {
  .apts   <- get_features(names(x))
  mode_ok <- vapply(x[, .apts], function(.x)
                    is.numeric(.x) || is.complex(.x), NA)
  if ( all(mode_ok) ) {
    x[, .apts] <- lapply(X = x[, .apts], FUN = .Generic, ...)
  } else {
    usethis::ui_stop(
      "Non-numeric variable(s) in `soma_adat` object \\
      where RFU values should be: {names(x[, .apts])[ !mode_ok ]}."
      )
  }
  return(x)
}

#' @importFrom stringr str_glue
#' @method Math soma.adat
#' @export
Math.soma.adat <- function(x, ...) {
  .msg <- stringr::str_glue(
    "The 'soma.adat' class is now 'soma_adat' (31 JAN 2019). \\
    This math generic `{.Generic}` will be deprecated.
    Please either:
    1) Re-class with x %<>% addClass('soma_adat')
    2) Re-call 'read_adat(file)' to pick up the new 'soma_adat' class."
  )
  .Deprecated(msg = .msg, package = "SomaDataIO")
  class(x) <- c("soma_adat", "data.frame")
  do.call(.Generic, list(x = x, ...))
}
