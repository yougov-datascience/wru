% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/merge_names.R
\name{merge_names}
\alias{merge_names}
\title{Surname probability merging function.}
\usage{
merge_names(voter.file, namesToUse, clean.names = TRUE)
}
\arguments{
\item{voter.file}{An object of class \code{data.frame}.  Must contain a row for each individual being predicted,
as well as a field named \code{\var{last}} containing each individual's surname.
If first name is also being used for prediction, the file must also contain a field
named \code{\var{first}}. If middle name is also being used for prediction, the field
must also contain a field named \code{\var{middle}}.}

\item{namesToUse}{A character vector identifying which names to use for the prediction.
The default value is \code{"last"}, indicating that only the last name will be used.
Other options are \code{"last, first"}, indicating that both last and first names will be
used, and \code{"last, first, middle"}, indicating that last, first, and middle names will all
be used.}

\item{clean.names}{A \code{TRUE}/\code{FALSE} object. If \code{TRUE},
any surnames in \code{\var{voter.file}} that cannot initially be matched
to the database will be cleaned, according to U.S. Census specifications,
in order to increase the chance of finding a match. Default is \code{TRUE}.}
}
\value{
Output will be an object of class \code{data.frame}. It will
 consist of the original user-input data with additional columns that
 specify the part of the name matched with Census data (\code{\var{surname.match}}),
 and the probabilities Pr(Race | Surname) for each racial group
 (\code{\var{p_whi}} for White, \code{\var{p_bla}} for Black,
 \code{\var{p_his}} for Hispanic/Latino,
 \code{\var{p_asi}} for Asian and Pacific Islander, and
 \code{\var{p_oth}} for Other/Mixed).
}
\description{
\code{merge_names} merges names in a user-input dataset with corresponding
 race/ethnicity probabilities derived from both the U.S. Census Surname List
 and Spanish Surname List and voter files from states in the Southern U.S.
}
\details{
This function allows users to match names in their dataset with database entries
 estimating P(name | ethnicity) for each of the five major racial groups for each
 name. The database probabilities are derived from both the U.S. Census Surname List
 and Spanish Surname List and voter files from states in the Southern U.S.

 By default, the function matches names as follows:
 1) Search raw surnames in the database;
 2) Remove any punctuation and search again;
 3) Remove any spaces and search again;
 4) Remove suffixes (e.g., "Jr") and search again (last names only)
 5) Split double-barreled names into two parts and search first part of name;
 6) Split double-barreled names into two parts and search second part of name;

 Each step only applies to names not matched in a previous step.
 Steps 2 through 6 are not applied if \code{clean.surname} is FALSE.

 Note: Any name appearing only on the Spanish Surname List is assigned a
 probability of 1 for Hispanics/Latinos and 0 for all other racial groups.
}
\examples{
\donttest{
data(voters)
merge_names(voters, 'last, first')
}
}
