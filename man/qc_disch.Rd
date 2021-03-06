% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/qc_disch.R
\name{qc_disch}
\alias{qc_disch}
\title{Quality Control - Discharge}
\usage{
qc_disch(
  qc_df = NULL,
  cols_to_check_nas = c("Discharge Location (BOS, TOS, CU #)")
)
}
\arguments{
\item{qc_df}{The survey data frame to be QC'd}

\item{cols_to_check_nas}{columns to check for NAs in}
}
\value{
a tibble with QC results
}
\description{
Quality control discharge data (e.g., from Discharge_5.csv files) imported
using \code{read_otg_csv()} or \code{read_otg_csv_wrapper()}.
}
\author{
Kevin See
}
