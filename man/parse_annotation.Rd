% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{parse_annotation}
\alias{parse_annotation}
\title{Parses annotations in the context of data. Special characters and syntax are substituted by
actual data and/or substituted for format that is better parsed via rendering functions
(e.g. plotly).}
\usage{
parse_annotation(data, text)
}
\arguments{
\item{data}{Data frame containing data to reference. Should include columns and labels referenced
in the text string. Referenced variables should be able to produce single unique
result.}

\item{text}{Character text to parse.}
}
\value{
Parsed annotation text.
}
\description{
Parses annotations in the context of data. Special characters and syntax are substituted by
actual data and/or substituted for format that is better parsed via rendering functions
(e.g. plotly).
}
\details{
\itemize{
\item \verb{\\n} character is substituted for \verb{<br>} tag in order to add new lines in rendered image.
\item \verb{$COLNAME} is parsed to provide unique data value from the mentioned column.
\item \code{!COLNAME} is parsed to provide \code{label} attribute for a given column name.
If any values are missing from the provided data, they are substituted for \code{ERR} string.
}
}
