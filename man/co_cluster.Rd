% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/co_cluster.R
\name{co_cluster}
\alias{co_cluster}
\title{Name-Race Co-clustering Using Keynames}
\usage{
co_cluster(
  voter.file,
  name_types,
  name_race_tables,
  census.geo,
  ...,
  control = NULL
)
}
\arguments{
\item{voter.file}{An object of class data.frame. Must contain a row for each individual being predicted, 
as well as fields named "surname", and/or"first", and/or "middle", containing each 
individual's corresponding names. It must also contain a field named state, which 
contains the two-character lower-case abbreviation for each individual's state of residence (e.g., "nj" for New Jersey).
If using Census geographic data in race/ethnicity
predictions, voter.file must also contain at least one of the following fields: county, tract, block,
and/or place. These fields should contain character strings matching U.S. Census categories. County is three
characters (e.g., "031" not "31"), tract is six characters, and block is four characters. Place is
five characters. See \code{\link{predict_race}} for other optional fields.}

\item{name_types}{Character vector. Must have elements in "surname", "first", and "middle".}

\item{name_race_tables}{Named list, with as many elements as there are names in \code{name_types}, and names matching
elements in \code{name_types}. Each list element should be a data.frame of unique names (first column) by race (remaining columns),
with conditional probabilities p(Name|Race).}

\item{census.geo}{Required character vector. One of "county", "tract", "block" or "place". See \code{\link{predict_race}}.}

\item{...}{Arguments passed to \code{\link{predict_race}}.}

\item{control}{List of control arguments, including 
\itemize{
\item{race_init}{ Initial race for each observation in voter.file. Must be an integer, with
                 0=white, 1=black, 2=hispanic, 3=asian, and 4=other.}
 \item{fit_insample}{ Boolean. Should model check in-sample fit of race prediction for each
                     record? If \code{TRUE}, \code{race_obs} cannot be \code{NULL}. Defaults to \code{FALSE}.}
 \item{race_obs}{ Observed race for each record in \code{voter.file}. Must be an integer, with
                 0=white, 1=black, 2=hispanic, 3=asian, and 4=other.}
 \item{iter}{ Number of MCMC iterations. Defaults to 1000.}
 \item{burnin}{ Number of iterations discarded as burnin. Defaults to half of \code{iter}.}
 \item{thin}{ Thinning interval for MCMC. Defaults to 1.}
 \item{log_post_interval}{ Interval for storing the log_posterior. Defaults to 10.}
 \item{beta_prior}{ Parameter for symmetric Dirichlet prior over names for each race. Defaults to 5.}
 \item{gamma_prior}{ Parameter for Beta prior over keyname/non-keyname mixture components. Defaults to c(5, 5).}
 \item{verbose}{ Print progress information. Defaults to \code{TRUE}.}
 \item{seed}{ RNG seed. If \code{NULL}, a seed is generated and stored for reproducibility.}
}}
}
\value{
A named list:
\itemize{
\item{name_by_race}{ Named list of predicted distributions of name by race for each name type.}
\item{race_by_record}{ A copy of \code{voter.file}, with additional columns of predicted
                      race probabilities, names \code{pred.<race>}. }
\item{loglik}{ Values of log likelihood, evaluated every \code{log_post_interval}.}
\item{fit_insample}{ When \code{fit_insample=TRUE}, a probability of correct in_sample prediction 
                     for each record in \code{vote.file}.} 
}
}
\description{
Estimate a Bayesian mixed-membership, keyword-assisted race classification model for geo-locations
in a voterfile.
}
