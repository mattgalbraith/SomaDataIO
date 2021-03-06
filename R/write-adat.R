#' Write an ADAT to File
#'
#' One can write an existing modified internal ADAT
#' (`soma_adat` R object) to an external file.
#' However the ADAT object itself *must* have intact
#' attributes, see [is.intact.attributes()].
#'
#' The ADAT specification *no longer* requires Windows
#' end of line (EOL) characters (\verb{"\r\n"}).
#' The EOL is currently \verb{"\n"} which is commonly used in POSIX systems,
#' like MacOS and Linux.
#' The EOL affects the format of the resulting file, particularly
#' calculating a checksum, therefore ADATs written via other systems may
#' result in differing EOLs. EOL encoding for operating systems is below:\cr
#' \tabular{llc}{
#'   Symbol \tab Platform    \tab Character \cr
#'   LF     \tab Linux       \tab \verb{"\n"} \cr
#'   CR     \tab MacOS       \tab \verb{"\r"} \cr
#'   CRLF   \tab DOS/Windows \tab \verb{"\r\n"}
#' }
#'
#' @family IO
#' @param x An object of class `"soma_adat"`. Both [is.soma_adat()] and
#' [is.intact.attributes()] must be `TRUE`.
#' @param file Character. File path where the object should be written.
#' For example, extensions should be `*.adat`.
#' @author Stu Field
#' @importFrom assertthat assert_that
#' @importFrom usethis ui_stop ui_warn ui_done ui_path
#' @importFrom purrr walk iwalk
#' @importFrom dplyr mutate select
#' @importFrom readr write_tsv write_lines
#' @importFrom stringr str_detect
#' @seealso [write_tsv()], [is.intact.attributes()].
#' @export write_adat
write_adat <- function(x, file) {

  if ( missing(file) ) {
    usethis::ui_stop("Must provide output file name ...")
  }

  assertthat::assert_that(inherits(x, "soma_adat"))

  if ( !stringr::str_detect(file, "\\.adat$") ) {
    usethis::ui_warn(
      "File extension is not `*.adat` ('{file}'). \\
      Are you sure this is the correct file extension?"
    )
  }

  apts <- .getfeat(x)
  atts <- prepHeaderMeta(x)
  attributes(x) <- atts

  # checks and traps
  checkADAT(x)

  # remove FEATURE_EXTRACTION & recalculate Checksum
  header_keep      <- setdiff(names(atts$Header.Meta),
                              c("Checksum", "FEATURE_EXTRACTION"))
  atts$Header.Meta <- atts$Header.Meta[ header_keep ]

  # open connection
  f  <- file(file, open = "wb")
  HM <- atts$Header.Meta      # Header Meta; rename for convenience

  purrr::walk(names(HM), function(i) {
    readr::write_lines(paste0("^", i), path = f, append = TRUE)
    if ( i == "TABLE_BEGIN" ) return(NULL)
    purrr::iwalk(HM[[i]], ~ {
      paste0("!", .y, "\t", paste0(.x, collapse = "\t")) %>%
        readr::write_lines(path = f, append = TRUE)
      })
  })

  # write Col Meta
  meta_names  <- .getmeta(x)
  length_meta <- length(meta_names)

  purrr::iwalk(atts$Col.Meta, ~ {
    paste0(stringr::str_dup("\t", length_meta),    # col shift
           .y, "\t",                               # name
           paste(.x, collapse = "\t")              # Col.Meta
          ) %>%
          readr::write_lines(path = f, append = TRUE)
  })

  # Write out header row
  # Skip rest if Adat is empty
  if ( nrow(x) != 0 ) {

    if ( length_meta < 1 ) {
      usethis::ui_warn("
        You are writing an ADAT without any meta data
        This will likely cause this file ({file}) to \\
        be unreadable using `read_adat()`
        Suggest including at least one column of meta data."
      )
    }

    tabs      <- stringr::str_dup("\t", length(apts) - 1)
    metanames <- paste(meta_names, collapse = "\t")
    readr::write_lines(paste0(metanames, "\t\t", tabs), path = f, append = TRUE)

    df <- x %>%
      dplyr::mutate(blank_col = NA_character_) %>%   # add mystery column
      dplyr::select(meta_names, blank_col, dplyr::everything())

    # write meta & feature data to file
    df[, apts] <- apply(df[, apts], 2, function(.x) sprintf("%0.1f", .x))

    # change 4000 -> 4e3 scientific mode; SampleUniqueID
    readr::write_tsv(x = df, path = f, na = "", append = TRUE)
  }

  close(f)
  usethis::ui_done("ADAT written to: {usethis::ui_path(file)}")
  invisible(x)
}
