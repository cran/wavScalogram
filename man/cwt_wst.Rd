% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cwt_wst.R
\name{cwt_wst}
\alias{cwt_wst}
\title{Continuous wavelet transform}
\usage{
cwt_wst(signal,
               dt = 1,
               scales = NULL,
               powerscales = TRUE,
               wname = c("MORLET", "DOG", "PAUL", "HAAR", "HAAR2"),
               wparam = NULL,
               waverad = NULL,
               border_effects = c("BE", "PER", "SYM"),
               makefigure = TRUE,
               time_values = NULL,
               energy_density = FALSE,
               figureperiod = TRUE)
}
\arguments{
\item{signal}{A vector containing the signal whose wavelet transform is wanted.}

\item{dt}{Numeric. The time step of the signal.}

\item{scales}{A vector containing the wavelet scales at wich the CWT is computed. This
can be either a vector with all the scales, or (if \code{powerscales} is TRUE)
following Torrence and Compo 1998, a vector of three elements with the minimum scale,
the maximum scale and the number of suboctaves per octave. If NULL, they are
automatically computed.}

\item{powerscales}{Logical. If TRUE (default), construct power 2 scales from
\code{scales}. If \code{scales} is NULL, they are automatically computed.}

\item{wname}{A string, equal to "MORLET", "DOG", "PAUL", "HAAR" or "HAAR2". The
difference between "HAAR" and "HAAR2" is that "HAAR2" is more accurate but slower.}

\item{wparam}{The corresponding nondimensional parameter for the wavelet function
(Morlet, DoG or Paul).}

\item{waverad}{Numeric. The radius of the wavelet used in the computations for the cone
of influence. If it is not specified, it is computed by \code{wavelet_radius} for DoG
and Paul wavelets. For Haar and Morlet it is assumed to be 1 and 3 respectively.}

\item{border_effects}{String, equal to "BE", "PER" or "SYM", which indicates how to
manage the border effects which arise usually when a convolution is performed on
finite-lenght signals.
\itemize{
\item "BE": Padding time series with zeroes.
\item "PER": Using boundary wavelets (periodization of the original time series).
\item "SYM": Using a symmetric catenation of the original time series.
}}

\item{makefigure}{Logical. If TRUE (default), a figure with the wavelet power spectrum
is plotted.}

\item{time_values}{A numerical vector of length \code{length(signal)} containing custom
time values for the figure. If NULL (default), it will be computed starting at 0.}

\item{energy_density}{Logical. If TRUE (default), divide the wavelet power spectrum by
the scales in the figure and so, values for different scales are comparable.}

\item{figureperiod}{Logical. If TRUE (default), periods are used in the figure instead
of scales.}
}
\value{
A list with the following fields:
\itemize{
\item \code{coefs}: A matrix of size \code{length(signal)} x \code{length(scales)},
containing the CWT coefficients of the signal.
\item \code{scales}: The vector of scales.
\item \code{fourier_factor}: A factor for converting scales to periods.
\item \code{coi_maxscale}: A vector of length \code{length(signal)} containing the
values of the maximum scale from which there are border effects at each time.
}
}
\description{
This function computes the continuous wavelet transform for some families of wavelet
bases: "MORLET", "DOG", "PAUL" and "HAAR".
It is a translation from the Matlab(R) function published by Torrence and Compo
(Torrence & Compo, 1998).

The difference between \code{cwt_wst} and \code{cwt} from package \code{Rwave} is that
\code{cwt_wst} normalizes using \eqn{L^2} and \code{cwt} uses \eqn{L^1}.
}
\section{References}{


C. Torrence, G. P. Compo. A practical guide to wavelet analysis. B. Am. Meteorol. Soc.
79 (1998), 61–78.
}

\examples{
dt <- 0.1
time <- seq(0, 50, dt)
signal <- c(sin(pi * time), sin(pi * time / 2))
cwt <- cwt_wst(signal = signal, dt = dt, energy_density = TRUE)

}