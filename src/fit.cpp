#include <RcppEigen.h>
#include "XName.h"
#include "keyWRU.h"

// [[Rcpp::plugins(cpp11)]]
// [[Rcpp::depends(RcppEigen)]]
// [[Rcpp::depends(RcppProgress)]]

//' Collapsed Gibbs sampler for keyWRU. Internal function
//'
//' @param data A list with the following elements
//' \itemize{
//'  \item{name_type_n}{Number of name types}
//'  \item{race_n}{Number of races}
//'  \item{geo_n}{Number of geolocations}
//'  \item{geo_race_table}{Matrix of conditional probabilities Pr(Race | Geolocation), with geolocations in the rows}
//'  \item{voters_per_geo}{Number of voterfile records per geolocation}
//'  \item{race_inits}{Table of initial race assignments per voterfile record}
//'  \item{name_data}{
//'                    \itemize{
//'                     \item{n_unique_names}{Number of unique names}
//'                     \item{record_name_id}{Name id corresponding to each voterfile record}
//'                     \item{keynames}{Integer matrix of name id's used as keynames for each race (race in the columns)}
//'                     \item{census_table}{Matrix of Pr(Name | Race), with races in the columns}
//'                     \item{beta_prior}{Scalar prior for name-race symmetric Dirichlet distribution}
//'                     \item{gamma_prior}{Vector prior shapes for keyname/non-keyname Beta mixture}
//'                    }
//'                  }
//' }
//' @param ctrl A list of control arguments; see \code{co_cluster} function for details.
//'
//' @keywords internal
// [[Rcpp::export]]
Rcpp::List keyWRU_fit(Rcpp::List data,
                      Rcpp::List ctrl)
{
  keyWRU model(data, ctrl);
  model.sample();
  Rcpp::List res = model.return_obj();
  return res;
}

