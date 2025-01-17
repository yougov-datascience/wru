#' Race prediction function.
#'
#' \code{predict_race_new} makes probabilistic estimates of individual-level race/ethnicity.
#'
#' This function implements the Bayesian race prediction methods outlined in
#' Imai, Olivella, and Rosenman (2021). The function produces probabilistic estimates of
#' individual-level race/ethnicity, based on name and geolocation.
#' @param voter.file An object of class \code{data.frame}.
#' Must contain a row for each individual being predicted,
#' as well as a field named \code{\var{last}} containing each individual's surname.
#' If first name is also being used for prediction, the file must also contain a field
#' named \code{\var{first}}. If middle name is also being used for prediction, the field
#' must also contain a field named \code{\var{middle}}.
#' Moreover, \code{\var{voter.file}} must contain a field named
#' \code{\var{state}}, which contains the two-character abbreviation for each individual's
#' state of residence (e.g., \code{"nj"} for New Jersey).
#' If using Census geographic data in race/ethnicity predictions,
#' \code{\var{voter.file}} must also contain at least one of the following fields:
#' \code{\var{county}}, \code{\var{tract}}, \code{\var{block}}, and/or \code{\var{place}}.
#' These fields should contain character strings matching U.S. Census categories.
#' County is three characters (e.g., \code{"031"} not \code{"31"}),
#' tract is six characters, and block is four characters. Place is five characters.
#' See below for other optional fields.
#' @param namesToUse A character vector identifying which names to use for the prediction.
#' The default value is \code{"last"}, indicating that only the last name will be used.
#' Other options are \code{"last, first"}, indicating that both last and first names will be
#' used, and \code{"last, first, middle"}, indicating that last, first, and middle names will all
#' be used.
#' @param census.geo An optional character vector specifying what level of
#' geography to use to merge in U.S. Census 2010 geographic data. Currently
#' \code{"county"}, \code{"tract"}, \code{"block"}, and \code{"place"} are supported.
#' Note: sufficient information must be in user-defined \code{\var{voter.file}} object.
#' If \code{\var{census.geo} = "county"}, then \code{\var{voter.file}}
#' must have column named \code{county}.
#' If \code{\var{census.geo} = "tract"}, then \code{\var{voter.file}}
#' must have columns named \code{county} and \code{tract}.
#' And if \code{\var{census.geo} = "block"}, then \code{\var{voter.file}}
#' must have columns named \code{county}, \code{tract}, and \code{block}.
#' If \code{\var{census.geo} = "place"}, then \code{\var{voter.file}}
#' must have column named \code{place}.
#' Specifying \code{\var{census.geo}} will call \code{census_helper} function
#' to merge Census geographic data at specified level of geography.
#' @param census.key A character object specifying user's Census API
#'  key. Required if \code{\var{census.geo}} is specified, because
#'  a valid Census API key is required to download Census geographic data.
#' @param census.data A list indexed by two-letter state abbreviations,
#' which contains pre-saved Census geographic data.
#' Can be generated using \code{get_census_data} function.
#' @param retry The number of retries at the census website if network interruption occurs.
#' @return Output will be an object of class \code{data.frame}. It will
#'  consist of the original user-input data with additional columns with
#'  predicted probabilities for each of the five major racial categories:
#'  \code{\var{pred.whi}} for White,
#'  \code{\var{pred.bla}} for Black,
#'  \code{\var{pred.his}} for Hispanic/Latino,
#'  \code{\var{pred.asi}} for Asian/Pacific Islander, and
#'  \code{\var{pred.oth}} for Other/Mixed.
#'
#' @export
#'
#' @examples
#' data(voters)
#' predict_race(voters, surname.only = TRUE)
#' predict_race(voter.file = voters, surname.only = TRUE)
#' \dontrun{predict_race(voter.file = voters, census.geo = "tract", census.key = "...")}
#' \dontrun{predict_race(voter.file = voters, census.geo = "tract", census.key = "...", age = T)}
#' \dontrun{predict_race(voter.file = voters, census.geo = "place", census.key = "...", sex = T)}
#' \dontrun{CensusObj <- get_census_data("...", state = c("NY", "DC", "NJ"));
#' predict_race(voter.file = voters, census.geo = "tract", census.data = CensusObj, party = "PID")}
#' \dontrun{CensusObj2 <- get_census_data(key = "...", state = c("NY", "DC", "NJ"), age = T, sex = T);
#' predict_race(voter.file = voters, census.geo = "tract", census.data = CensusObj2, age = T, sex = T)}
#' \dontrun{CensusObj3 <- get_census_data(key = "...", state = c("NY", "DC", "NJ"), census.geo = "place");
#' predict_race(voter.file = voters, census.geo = "place", census.data = CensusObj3)}
predict_race_new <- function(voter.file, namesToUse = 'last', census.geo, census.key,
                         census.data = NA, retry = 3) {

  # check the geography
  if (!missing(census.geo) && (census.geo == "precinct")) {
    stop('Error: census_helper function does not currently support merging precinct-level data.')
  }

  vars.orig <- names(voter.file)

  # check the names
  if(namesToUse == 'last') {
    message("Proceeding with last name-only predictions...")
    if(!("last" %in% names(voter.file)))
      stop("Voter data frame needs to have a column named 'last'.")

  } else if(namesToUse == 'last, first') {
    message("Proceeding with first and last name-only predictions...")
    if(!("last" %in% names(voter.file)) || !("first" %in% names(voter.file)))
      stop("Voter data frame needs to have a column named 'last' and a column called 'first'.")

  } else if(namesToUse == 'last, first, middle') {
    message("Proceeding with first, last, and middle name predictions...")
    if(!("last" %in% names(voter.file)) || !("first" %in% names(voter.file))
       || !("middle" %in% names(voter.file)))
      stop("Voter data frame needs to have a column named 'last', a column called 'first', and a column called 'middle'.")
  }

  # check the geographies
  if (missing(census.geo) || is.null(census.geo) || is.na(census.geo) || census.geo %in% c("county", "tract", "block", "place") == F) {
    stop("census.geo must be either 'county', 'tract', 'block', or 'place'")
  } else {
    message(paste("Proceeding with Census geographic data at", census.geo, "level..."))
  }
  if (missing(census.data) || is.null(census.data) || is.na(census.data)) {
    if (missing(census.key) || is.null(census.key) || is.na(census.key)) {
      stop("Please provide a valid Census API key using census.key option.")
      } else {
        message("Downloading Census geographic data using provided API key...")
      }
    } else {
      if (!("state" %in% names(voter.file))) {
        stop("voter.file object needs to have a column named state.")
      }
      if (sum(toupper(unique(as.character(voter.file$state))) %in% toupper(names(census.data)) == FALSE) > 0) {
        message("census.data object does not include all states in voter.file object.")
        if (missing(census.key) || is.null(census.key) || is.na(census.key)) {
          stop("Please provide either a valid Census API key or valid census.data object that covers all states in voter.file object.")
        } else {
          message("Downloading Census geographic data for states not included in census.data object...")
        }
      } else {
        message("Using Census geographic data from provided census.data object...")
      }
    }

  eth <- c("whi", "bla", "his", "asi", "oth")

  ## Merge in Pr(Name | Race)
  voter.file <- merge_names(voter.file, namesToUse)

  if (census.geo == "place") {
    if (!("place" %in% names(voter.file))) {
      stop("voter.file object needs to have a column named place.")
    }
    voter.file <- census_helper_new(key = census.key,
                                    voter.file = voter.file,
                                    states = "all",
                                    geo = "place",
                                    census.data = census.data, retry = retry)
  }

  if (census.geo == "block") {
    if (!("tract" %in% names(voter.file)) || !("county" %in% names(voter.file)) || !("block" %in% names(voter.file))) {
      stop("voter.file object needs to have columns named block, tract, and county.")
    }
    voter.file <- census_helper_new(key = census.key,
                                    voter.file = voter.file,
                                    states = "all",
                                    geo = "block",
                                    census.data = census.data, retry = retry)
  }

  if (census.geo == "precinct") {
    geo <- "precinct"
    stop('Error: census_helper function does not currently support precinct-level data.')
  }

  if (census.geo == "tract") {
    if (!("tract" %in% names(voter.file)) || !("county" %in% names(voter.file))) {
      stop("voter.file object needs to have columns named tract and county.")
    }
    voter.file <- census_helper_new(key = census.key,
                                    voter.file = voter.file,
                                    states = "all",
                                    geo = "tract",
                                    census.data = census.data, retry = retry)
  }

  if (census.geo == "county") {
    if (!("county" %in% names(voter.file))) {
      stop("voter.file object needs to have a column named county.")
    }
    voter.file <- census_helper_new(key = census.key,
                                    voter.file = voter.file,
                                    states = "all",
                                    geo = "county",
                                    census.data = census.data, retry = retry)
  }
  
  # Pr(Race | Surname, Geolocation)
  preds <- voter.file[,grep("_last", names(voter.file))]*voter.file[,grep("r_", names(voter.file))]
  if(grepl('first', namesToUse))
    preds <- preds*voter.file[,grep("_first", names(voter.file))]
  if(grepl('middle', namesToUse))
    preds <- preds*voter.file[,grep("_middle", names(voter.file))]
  preds <- apply(preds, 2, FUN = function(x) {x/rowSums(preds)})
  colnames(preds) <- paste("pred", eth, sep = "_")

  return(data.frame(cbind(voter.file[c(vars.orig)], preds)))
}
