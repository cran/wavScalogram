#' @title Wavelet plots
#'
#' @description This function plots a function of two variables (usually times and
#' scales). It is suitable for plotting windowed scalograms, windowed scalogram
#' differences, wavelet coherences and windowed scale indices.
#'
#' @usage wavPlot(Z,
#'                X = NULL,
#'                Y = NULL,
#'                Ylog = FALSE,
#'                Yrev = TRUE,
#'                zlim = NULL,
#'                coi = NULL,
#'                rdist = NULL,
#'                sig95 = NULL,
#'                sig05 = NULL,
#'                Xname = "X",
#'                Yname = "Y",
#'                Zname = "Z")
#'
#' @param Z A matrix with the images of the function to be plotted.
#' @param X A vector with x-coordinates (times).
#' @param Y A vector with y-coordinates (scales).
#' @param Ylog Logical. Considers logarithmic scale for the y-axis.
#' @param Yrev Logical. Considers reverse the y-axis.
#' @param zlim A vector of length 2 with the limits for the z-axis (the color bar).
#' @param coi A vector of size \code{length(X)} with the y-coordinates of the frontier of
#' the cone of influence.
#' @param rdist Numeric. Only for WSD plots, margin in the y-axis where appear border
#' effects.
#' @param sig95 Logical matrix with the same size as Z. TRUE if the corresponding point in
#' Z is inside the significance at 95\%.
#' @param sig05 Logical matrix with the same size as Z. TRUE if the corresponding point in
#' Z is inside the significance at 5\%.
#' @param Xname A string with the name of the x-axis.
#' @param Yname A string with the name of the y-axis.
#' @param Zname A string with the name of the function.
#'
#' @importFrom fields image.plot
#' @importFrom grDevices colorRampPalette rgb
#' @importFrom graphics axis contour image lines plot segments
#' @importFrom stats quantile rnorm sd
#'
#' @examples
#'
#' nt <- 1500
#' time <- 1:nt
#' sd_noise <-  0.2 #% In Bolós et al. 2017 Figure 1, sd_noise = 1.
#' signal1 <- rnorm(n = nt, mean = 0, sd = sd_noise) + sin(time / 10)
#' signal2 <- rnorm(n = nt, mean = 0, sd = sd_noise) + sin(time / 10)
#' signal2[500:1000] = signal2[500:1000] + sin((500:1000) / 2)
#' \dontrun{
#' wsd <- wsd(signal1 = signal1, signal2 = signal2, mc_nrand = 10, makefigure = FALSE)
#' wavPlot(Z = -log2(wsd$wsd), X = wsd$t, Y = wsd$scales, Ylog = TRUE, coi = wsd$coi,
#'         rdist = wsd$rdist, sig95 = wsd$signif95, sig05 = wsd$signif05, Xname = "Time",
#'         Yname = "Scale", Zname = "-log2(WSD)")
#' }
#'
#' @export
#'


wavPlot <-
  function(Z,
           X = NULL,
           Y = NULL,
           Ylog = FALSE,
           Yrev = TRUE,
           zlim = NULL,
           coi = NULL,
           rdist = NULL,
           sig95 = NULL,
           sig05 = NULL,
           Xname = "X",
           Yname = "Y",
           Zname = "Z") {

  Xlen <- dim(Z)[1]
  Ylen <- dim(Z)[2]
  if (is.null(X)) {
    X <- 1:Xlen
  }
  if (is.null(Y)) {
    Y <- 1:Ylen
  }

  COLORS <- c("#0000AA",  "#000EB8", "#001CC6", "#002BD4", "#0039E3", "#0047F1",
              "#0055FF", "#0063FF", "#0071FF", "#0080FF", "#008EFF",
              "#009CFF",  "#00AAFF", "#0DB8FF", "#1BC6FF", "#28D4FF", "#36E3FF",
              "#43F1FF", "#51FFFF", "#5EFFF2", "#6BFFE4", "#79FFD7",
              "#86FFC9",  "#94FFBC", "#A1FFAE", "#AEFFA1", "#BCFF94", "#C9FF86",
              "#D7FF79", "#E4FF6B", "#F2FF5E", "#FFFF51", "#FFF143",
              "#FFE336",  "#FFD528", "#FFC61B", "#FFB80D", "#FFAA00", "#FF9C00",
              "#FF8E00", "#FF8000", "#FF7100", "#FF6300", "#FF5500",
              "#F14700",  "#E33900", "#D52B00", "#C61C00", "#B80E00", "#AA0000")

  if (Ylog) {
    YY <- log2(Y)
    Ystep <- 1
    #labels <- floor(2 ^ (seq(from = YY[1], to = YY[Ylen], by = Ystep)))
    labels <- round(2 ^ (seq(from = YY[1], to = YY[Ylen], by = Ystep)), 2)
    if(!is.null(coi)) {
      plotcoi <- log2(coi)
    }
  } else {
    YY <- Y
    Ystep <- (Y[Ylen] - Y[1]) / 6
    #labels <- floor(seq(from = YY[1], to = YY[Ylen], by = Ystep))
    labels <- round(seq(from = YY[1], to = YY[Ylen], by = Ystep), 2)
    if(!is.null(coi)) {
      plotcoi <- coi
    }
  }

  if (Yrev) {
    Yini <- Ylen
    Yend <- 1
    Ystep <- -Ystep
    if(!is.null(coi)) {
      plotcoi <- (YY[Ylen] - plotcoi + YY[1])
    }
  } else {
    Yini <- 1
    Yend <- Ylen
  }

  image.plot(
    X,
    YY,
    Z[, Yini:Yend],
    col = COLORS,
    yaxt = "n",
    xlab = Xname,
    ylab = Yname,
    main = Zname,
    ylim = c(YY[1], YY[Ylen]),
    zlim = zlim
    )

  # Axis ticks and labels
  axis(
    side = 2,
    at = seq(from = YY[Yini], to = YY[Yend], by = Ystep),
    labels = labels
  )

  # COI
  if (!is.null(coi)) {
    coi_matrix <- matrix(NA, nrow = Xlen, ncol = Ylen)
    for (i in 1:Xlen) {
      coi_matrix[i, Y > coi[i]] <- 1
    }

    pal <- colorRampPalette(c(rgb(1, 1, 1), rgb(0, 0, 0)))
    COLORS2 <- add.alpha(pal(20), 0.5)
    image(X,
          YY,
          coi_matrix[, Yini:Yend],
          col = COLORS2,
          add = T)

    segments(x0 = X[-Xlen], x1 = X[-1], y0 = plotcoi[-Xlen], y1 = plotcoi[-1])
  }

  # Y margins
  if (!is.null(rdist)) {
    ymargin_up <- numeric(Xlen)
    ymargin_down <- YY[rdist]
    ymargin_matrix <- matrix(NA, nrow = Xlen, ncol = Ylen)
    ymargin_matrix[, 1:rdist] <- 1
    for (i in 1:Xlen) {
      aux <- max(which(!is.na(Z[i, ])))-rdist+1
      ymargin_up[i] <- YY[aux]
      ymargin_matrix[i, aux:Ylen] <- 1
    }
    if (Yrev) {
      ymargin_up <- (YY[Ylen] - ymargin_up + YY[1])
      ymargin_down <- (YY[Ylen] - ymargin_down + YY[1])
    }

    pal <- colorRampPalette(c(rgb(1, 1, 1), rgb(0, 0, 0)))
    COLORS2 <- add.alpha(pal(20), 0.5)
    image(X,
          YY,
          ymargin_matrix[, Yini:Yend],
          col = COLORS2,
          add = T)
    segments(x0 = X[1], x1 = X[Xlen], y0 = ymargin_down, y1 = ymargin_down)
    segments(x0 = X[-Xlen], x1 = X[-1], y0 = ymargin_up[-Xlen], y1 = ymargin_up[-1])
  }

  # Significance levels
  if (!is.null(sig95)) {
    contour(x = X, y = YY, z = sig95[, Yini:Yend], levels = 1, col = "black", lwd = 1, drawlabels = FALSE, add = TRUE)
  }
  if (!is.null(sig05)) {
    contour(x = X, y = YY, z = sig05[, Yini:Yend], levels = 1, col = "white", lwd = 1, drawlabels = FALSE, add = TRUE)
  }

}




add.alpha <- function(COLORS, ALPHA){
  if(missing(ALPHA)) stop("provide a value for alpha between 0 and 1")
  RGB <- grDevices::col2rgb(COLORS, alpha=TRUE)
  RGB[4,] <- round(RGB[4,]*ALPHA)
  NEW.COLORS <- grDevices::rgb(RGB[1,], RGB[2,], RGB[3,], RGB[4,], maxColorValue = 255)
  return(NEW.COLORS)
}


