#' @title Continuous wavelet transform
#'
#' @description
#' This function computes the continuous wavelet transform for some families of wavelet
#' bases: "MORLET", "DOG", "PAUL" and "HAAR".
#' It is a translation from the Matlab(R) function published by Torrence and Compo
#' (Torrence & Compo, 1998).
#'
#' The difference between \code{cwt_wst} and \code{cwt} from package \code{Rwave} is that
#' \code{cwt_wst} normalizes using \eqn{L^2} and \code{cwt} uses \eqn{L^1}.
#'
#'
#' @usage cwt_wst(signal,
#'                dt = 1,
#'                scales = NULL,
#'                powerscales = TRUE,
#'                wname = c("MORLET", "DOG", "PAUL", "HAAR", "HAAR2"),
#'                wparam = NULL,
#'                waverad = NULL,
#'                border_effects = c("BE", "PER", "SYM"),
#'                makefigure = TRUE,
#'                time_values = NULL,
#'                energy_density = FALSE,
#'                figureperiod = TRUE,
#'                xlab = "Time",
#'                ylab = NULL,
#'                main = NULL,
#'                zlim = NULL)
#'
#' @param signal A vector containing the signal whose wavelet transform is wanted.
#' @param dt Numeric. The time step of the signal.
#' @param scales A vector containing the wavelet scales at which the CWT
#' is computed. This can be either a vector with all the scales or, following Torrence
#' and Compo 1998, a vector of 3 elements with the minimum scale, the maximum scale and
#' the number of suboctaves per octave (in this case, \code{powerscales} must be TRUE in
#' order to construct power 2 scales using a base 2 logarithmic scale). If \code{scales}
#' is NULL, they are automatically constructed.
#' @param powerscales Logical. It must be TRUE (default) in these cases:
#' \itemize{
#' \item If \code{scales} are power 2 scales, i.e. they use a base 2 logarithmic scale.
#' \item If we want to construct power 2 scales automatically. In this case, \code{scales}
#' must be \code{NULL}.
#' \item If we want to construct power 2 scales from \code{scales}. In this case,
#' \code{length(scales)} must be 3.
#' }
#' @param wname A string, equal to "MORLET", "DOG", "PAUL", "HAAR" or "HAAR2". The
#' difference between "HAAR" and "HAAR2" is that "HAAR2" is more accurate but slower.
#' @param wparam The corresponding nondimensional parameter for the wavelet function
#' (Morlet, DoG or Paul).
#' @param waverad Numeric. The radius of the wavelet used in the computations for the cone
#' of influence. If it is not specified, it is asumed to be \eqn{\sqrt{2}} for Morlet and DoG,
#' \eqn{1/\sqrt{2}} for Paul and 0.5 for Haar.
#' @param border_effects String, equal to "BE", "PER" or "SYM", which indicates how to
#' manage the border effects which arise usually when a convolution is performed on
#' finite-length signals.
#' \itemize{
#' \item "BE": Padding time series with zeroes.
#' \item "PER": Using boundary wavelets (periodization of the original time series).
#' \item "SYM": Using a symmetric catenation of the original time series.
#' }
#' @param makefigure Logical. If TRUE (default), a figure with the wavelet power spectrum
#' is plotted.
#' @param time_values A numerical vector of length \code{length(signal)} containing custom
#' time values for the figure. If NULL (default), it will be computed starting at 0.
#' @param energy_density Logical. If TRUE (default), divide the wavelet power spectrum by
#' the scales in the figure and so, values for different scales are comparable.
#' @param figureperiod Logical. If TRUE (default), periods are used in the figure instead
#' of scales.
#' @param xlab A string giving a custom X axis label.
#' @param ylab A string giving a custom Y axis label. If NULL (default) the Y label is
#' either "Scale" or "Period" depending on the value of \code{figureperiod}.
#' @param main A string giving a custom main title for the figure. If NULL
#' (default) the main title is either "Wavelet Power Spectrum / Scales" or "Wavelet Power
#' Spectrum" depending on the value of \code{energy_density}.
#' @param zlim A vector of length 2 with the limits for the z-axis (the color bar).
#'
#' @return A list with the following fields:
#' \itemize{
#' \item \code{coefs}: A matrix of size \code{length(signal)} x \code{length(scales)},
#' containing the CWT coefficients of the signal.
#' \item \code{scales}: The vector of scales.
#' \item \code{fourierfactor}: A factor for converting scales into periods.
#' \item \code{coi_maxscale}: A vector of length \code{length(signal)} containing the
#' values of the maximum scale from which there are border effects at each time.
#' }
#'
#' @examples
#' dt <- 0.1
#' time <- seq(0, 50, dt)
#' signal <- c(sin(pi * time), sin(pi * time / 2))
#' cwt <- cwt_wst(signal = signal, dt = dt, energy_density = TRUE)
#'
#' @section References:
#'
#' C. Torrence, G. P. Compo. A practical guide to wavelet analysis. B. Am. Meteorol. Soc.
#' 79 (1998), 61–78.
#'
#' @export
#'

cwt_wst <-
  function(signal,
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
           figureperiod = TRUE,
           xlab = "Time",
           ylab = NULL,
           main = NULL,
           zlim = NULL
           ) {

  wname <- toupper(wname)
  wname <- match.arg(wname)

  if (is.null(waverad)) {
    if ((wname == "MORLET") || (wname == "DOG")) {
      waverad <- sqrt(2)
    } else if (wname == "PAUL") {
      waverad <- 1 / sqrt(2)
    } else { # HAAR
      waverad <- 0.5
    }
  }

  border_effects <- toupper(border_effects)
  border_effects <- match.arg(border_effects)

  nt <- length(signal)

  fourierfactor <- fourier_factor(wname = wname, wparam = wparam)

  if (is.null(scales)) {
    scmin <- 2 / fourierfactor
    scmax <- floor(nt / (2 * waverad))
    if (powerscales) {
      scales <- pow2scales(c(scmin, scmax, ceiling(256 / log2(scmax / scmin))))
    } else {
      scales <- seq(scmin, scmax, by = (scmax - scmin) / 256)
    }
    scalesdt <- scales * dt
  } else {
    if (powerscales && length(scales) == 3) {
      scales <- pow2scales(scales)
    } else {
      if (is.unsorted(scales)) {
        warning("Scales were not sorted.")
        scales <- sort(scales)
      }
      aux <- diff(log2(scales))
      if (powerscales && ((max(aux) - min(aux)) / max(aux) > 0.05)) {
        warning("Scales seem like they are not power 2 scales. Powerscales set to FALSE.")
        powerscales <- FALSE
      }
    }
    scalesdt <- scales
    scales <- scales / dt
  }

  ns <- length(scales)

  if (border_effects == "BE") {

    nt_ini <- 1
    nt_end <- nt

  } else if (border_effects == "PER") {

    ndatcat <- ceiling(ceiling(waverad * scales[ns]) / nt) # Number of catenations = ndatcat * 2 + 1
    ntcat <- (ndatcat * 2 + 1) * nt
    datcat <- numeric(ntcat)
    for (itcat in 1:ntcat) {
      datcat[itcat] = signal[itcat - floor((itcat - 1) / nt) * nt]
    }
    signal <- datcat
    nt_ini <- ndatcat * nt + 1
    nt_end <- nt_ini + nt - 1

  } else if (border_effects == "SYM") {

    ndatcat <- ceiling(ceiling(waverad * scales[ns]) / nt) # Number of catenations = ndatcat * 2 + 1
    dat_sym <- signal
    aux <- rev(signal)
    for (icat in 1:ndatcat) {
      dat_sym <- c(aux, dat_sym, aux)
      aux <- rev(aux)
    }
    signal <- dat_sym
    nt_ini <- ndatcat * nt + 1
    nt_end <- nt_ini + nt - 1

  }

  nt <- length(signal)
  coefs <- matrix(0, nrow = nt, ncol = ns)

  if (wname == "HAAR") {

    precision <- max(12, floor(log2(max(scales))) + 4)
    step <- 2 ^ (-precision)
    xval <- seq(from = 0, to = 1 + step, by = step)
    xmax <- max(xval)
    psi_integ <- xval * (xval < 1 / 2) + (1 - xval) * (xval >= 1 / 2)
    for (k in 1:ns) {
      a <- scales[k]
      j <- 1 + floor((0:a * xmax) / (a * step))
      if (length(j) == 1) {
        j <- c(1, 1)
      }
      f <- rev(psi_integ[j])
      coefs[, k] <- -sqrt(a) * core(diff(stats::convolve(signal, f, type = "open")), nt)
    }

  } else if (wname == "HAAR2") {

    for (j in 1:ns) {
      kmatrix <-  matrix(0, nrow = nt, ncol = nt)
      klen <- floor((scales[j] - 1) / 2)
      kfrac <- (((scales[j] - 1) / 2) - klen)
      for (i in 1:nt) {
        kmin <- max(1, i - klen)
        kmax <- min(nt, i + klen)
        if (kmin <= (i - 1)) {
          kmatrix[kmin:(i - 1), i] <- 1
          #for (k in kmin:(i - 1)) {
          #  coefs[i, j] = coefs[i, j] + signal[k]
          #}
        }
        if (kmin >= 2) {
          kmatrix[kmin - 1, i] <- kfrac
          #coefs[i, j] <- coefs[i, j] + signal[kmin - 1] * kfrac
        }
        if (kmax >= (i + 1)) {
          kmatrix[(i + 1):kmax, i] <- -1
          #for (k in (i + 1):kmax) {
          #  coefs[i, j] = coefs[i, j] - signal[k]
          #}
        }
        if (kmax <= (nt - 1)) {
          kmatrix[kmax + 1, i] <- -kfrac
          #coefs[i, j] <- coefs[i, j] - signal[kmax + 1] * kfrac
        }
      }
      coefs[, j] <- signal %*% kmatrix / sqrt(scales[j])
      #coefs[, j] <- coefs[, j] / sqrt(scales[j])
    }

  } else {

    f <- stats::fft(signal)
    k <- 1:trunc(nt / 2)
    k <- k * 2 * pi / nt
    k <- c(0, k, -k[trunc((nt - 1) / 2):1])
    n <- length(k)

    if (wname == "MORLET") {

      if (is.null(wparam)) {
        wparam <- 6
      }
      expnt <- -(diag(x = scales, ncol = ns) %*% matrix(rep(k, ns), nrow = ns, byrow = T) - wparam) ^ 2 / 2
      expnt <- sweep(expnt, MARGIN = 2, (k > 0), `*`)
      Norm <- sqrt(scales * k[2])  *pi ^ (-.25) * sqrt(n)
      daughter <- diag(x = Norm, ncol = ns) %*% exp(expnt)
      daughter <- sweep(daughter, MARGIN = 2, (k > 0), `*`)

      coefs <- coefs + 1i*coefs

    } else if (wname == "PAUL") {

      if (is.null(wparam)) {
        wparam <- 4
      }
      coefs <- coefs + 1i*coefs
      expnt <- -diag(x = scales, ncol = ns) %*% matrix(rep(k, ns), nrow = ns, byrow = T)
      expnt <- sweep(expnt, MARGIN = 2, (k > 0), `*`)
      Norm <- sqrt(scales * k[2]) * (2 ^ wparam / sqrt(wparam * prod(2:(2 * wparam - 1)))) * sqrt(n)
      daughter <- diag(x = Norm, ncol = ns) %*% expnt ^ wparam * exp(expnt)
      daughter <- sweep(daughter, MARGIN = 2, (k > 0), `*`)

      coefs <- coefs + 1i*coefs

    } else if (wname == "DOG") {

      if (is.null(wparam)) {
        wparam <- 2
      }
      preexpnt <- (diag(x = scales, ncol = ns) %*% matrix(rep(k, ns), nrow = ns, byrow = T))
      expnt <- -preexpnt ^ 2 / 2
      Norm <- sqrt(scales * k[2] / gamma(wparam + 0.5)) * sqrt(n)
      daughter <- diag(x = -Norm * (1i ^ wparam), ncol = ns) %*% preexpnt ^ wparam * exp(expnt)

    }

    coefs <- stats::mvfft(t(sweep(daughter, MARGIN = 2, f, `*`)), inverse = TRUE) / length(f)

  }

  coefs <- coefs[nt_ini:nt_end, 1:ns] * sqrt(dt)
  nt <- nt_end - nt_ini + 1

  # COI
  coi_maxscale <- numeric(nt)
  for (i in 1:nt) {
    coi_maxscale[i] <- dt * min(i - 1, nt - i) / waverad
  }

  # Make figure
  if (makefigure) {

    if (is.null(time_values)) {
      X <- seq(0, (nt - 1) * dt, dt)
    } else {
      if (length(time_values) != nt) {
        warning("Invalid length of time_values vector. Changing to default.")
        X <- seq(0, (nt - 1) * dt, dt)
      } else {
      X <- time_values
      }
    }

    ylab_aux <- ylab
    if (figureperiod) {
      Y <- fourierfactor * scalesdt
      coi <- fourierfactor * coi_maxscale
      if (is.null(ylab)) ylab  <- "Period"
    } else {
      Y <- scalesdt
      coi <- coi_maxscale
      if (is.null(ylab)) ylab <- "Scale"
    }

    if (energy_density) {
      Z <- t(t(abs(coefs) ^ 2) / scalesdt)
      if (is.null(main)) main <- "Wavelet Power Spectrum / Scales"
    } else {
      Z <- abs(coefs) ^ 2
      if (is.null(main)) main <- "Wavelet Power Spectrum"
    }

    if (ns > 1) {
      wavPlot(
        Z = Z,
        X = X,
        Y = Y,
        Ylog = powerscales,
        coi = coi,
        Xname = xlab,
        Yname = ylab,
        Zname = main,
        zlim = zlim
      )
    } else {
      if (is.null(ylab_aux)) {
        if (energy_density) {
          ylab <- "Wavelet Power Spectrum / Scales"
        } else {
          ylab <- "Wavelet Power Spectrum"
        }
      }
      plot(X, Z, type = "l", xlab = xlab, ylab = ylab, main = main, xaxt = "n")
      axis(side = 1, at = X[1 + floor((0:8) * (nt - 1) / 8)])
      abline(v = range(X[(coi > Y)]), lty = 2)
    }

  }

  return(list(
    coefs = coefs,
    scales = scalesdt,
    fourierfactor = fourierfactor,
    coi_maxscale = coi_maxscale
  ))

}

#' @title Extracts the center of a vector
#'
#' @description
#' This function is an internal function which extracts from a vector \code{x},
#' the center of the vector of length \code{n}. It emulates the Matlab(R) function \code{wkeep}.
#' This function is used by the cwt_wst function when the HAAR wavelet is selected.
#' @usage core(x,n)
#'
#' @param x A vector from wich the center is extracted.
#' @param n Numeric. The length of the center of \code{x}.


core <- function(x, n) {
  if (n > length(x)) {
    stop("Error. The length of the vector x should be greater than n.")
  }
  if (n == length(x)) {
    extracted <- x
  } else {
    if (length(x) %% 2 == 0){ # Length of x is even
      center1 <- length(x) / 2
      center2 <- length(x) / 2 + 1
      if (n %% 2 == 1) { # n is odd
        n1 <- center1 - floor(n / 2)
        n2 <- center2 + floor(n / 2) - 1
      } else { # n is even
        n1 <- center1 - (n / 2 - 1)
        n2 <- center2 + (n / 2 - 1)
      }
    } else { # Length of x is odd
      center <- floor(length(x) / 2) + 1
      if (n %% 2 == 1) { # n is odd
        n1 <- center - floor(n / 2)
        n2 <- center + floor(n / 2)
      } else { # n is even
        n1 <- center - n / 2
        n2 <- center + (n / 2 - 1)
      }
    }
    extracted <- x[n1:n2]
  }
  return(extracted)
}

