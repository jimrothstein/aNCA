% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/label_operators.R
\name{has_label}
\alias{has_label}
\title{Check if a Vector Has a Label}
\usage{
has_label(x)
}
\arguments{
\item{x}{A vector to be checked for a "label" attribute.}
}
\value{
A logical value indicating whether the vector has a "label" attribute.
}
\description{
This function checks if a vector has a "label" attribute.
}
\examples{
\dontrun{
  # Example usage:
  vec <- c("A", "B", "C")
  attr(vec, "label") <- "Example Label"
  has_label(vec)  # Returns TRUE
}

}
