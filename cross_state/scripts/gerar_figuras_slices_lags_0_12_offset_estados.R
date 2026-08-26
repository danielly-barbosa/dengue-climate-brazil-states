build_slice_list <- function(pred_obj, lags = 0:12) {
  lapply(lags, function(lag_val) {
    lag_col <- paste0("lag", lag_val)

    data.frame(
      lag = lag_val,
      indexP = pred_obj$predvar,
      rr = pred_obj$matRRfit[, lag_col],
      rr_low = pred_obj$matRRlow[, lag_col],
      rr_high = pred_obj$matRRhigh[, lag_col]
    )
  })
}

draw_lag_panel <- function(slice_data, xlim, xticks, ylim) {
  x <- slice_data$indexP
  y <- slice_data$rr
  y_low <- slice_data$rr_low
  y_high <- slice_data$rr_high

  plot(
    x, y,
    type = "n",
    xlim = xlim,
    ylim = ylim,
    xlab = "Index P",
    ylab = "Relative Risk",
    xaxt = "n",
    yaxt = "n",
    bty = "l",
    xaxs = "i",
    yaxs = "i"
  )

  usr <- par("usr")
  rect(usr[1], usr[3], usr[2], usr[4], col = "grey92", border = NA)

  polygon(
    c(x, rev(x)),
    c(y_low, rev(y_high)),
    col = "grey70",
    border = NA
  )
  abline(h = 1, col = "black", lwd = 0.8)
  lines(x, y, col = "red", lwd = 1)
  axis(1, at = xticks, labels = format(xticks, trim = TRUE), cex.axis = 0.8)
  axis(2, at = seq(ylim[1], ylim[2], by = 1), las = 1, cex.axis = 0.8)
  title(main = paste("Lag =", slice_data$lag[1]), cex.main = 1)
}

layout_matrix_3x4 <- matrix(1:12, nrow = 4, byrow = TRUE)

save_panel <- function(
  output_path,
  device_fun,
  slice_list,
  title_text,
  xlim,
  xticks,
  ylim,
  layout_matrix,
  ...
) {
  device_fun(output_path, ...)
  op <- par(
    mar = c(4.2, 4.2, 2.1, 1.2),
    oma = c(0.5, 0.5, 3.2, 0.5),
    mgp = c(2.2, 0.7, 0),
    tcl = -0.25
  )
  on.exit({
    par(op)
    dev.off()
  }, add = FALSE)

  layout(
    layout_matrix,
    widths = rep(1, ncol(layout_matrix)),
    heights = rep(1, nrow(layout_matrix))
  )

  invisible(lapply(slice_list, draw_lag_panel, xlim = xlim, xticks = xticks, ylim = ylim))

  mtext(
    title_text,
    side = 3,
    outer = TRUE,
    line = 1.2,
    cex = 1.1,
    font = 2
  )
}

save_single_panel <- function(output_path, device_fun, slice_data, title_text, xlim, xticks, ylim, ...) {
  device_fun(output_path, ...)
  op <- par(
    mar = c(4.2, 4.2, 2.1, 1.2),
    oma = c(0.5, 0.5, 2.6, 0.5),
    mgp = c(2.2, 0.7, 0),
    tcl = -0.25
  )
  on.exit({
    par(op)
    dev.off()
  }, add = FALSE)

  draw_lag_panel(slice_data, xlim = xlim, xticks = xticks, ylim = ylim)

  mtext(
    title_text,
    side = 3,
    outer = TRUE,
    line = 1,
    cex = 1.05,
    font = 2
  )
}

states <- list(
  list(
    code = "PE",
    title_state = "Pernambuco",
    input_file = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/resultados/summaries/resultados_indexP_offset.RData",
    output_dir = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/PE DLNM MASS + OFFSET/resultados/figuras/individuais/indexP"
  ),
  list(
    code = "GO",
    title_state = "Goias",
    input_file = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/GO DLNM MASS + OFFSET/resultados/summaries/resultados_indexP_offset.RData",
    output_dir = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/GO DLNM MASS + OFFSET/resultados/figuras/individuais/indexP"
  ),
  list(
    code = "RJ",
    title_state = "Rio de Janeiro",
    input_file = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/RIO DE JANEIRO DLNM MASS + OFFSET/resultados/summaries/resultados_indexP_offset.RData",
    output_dir = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/RIO DE JANEIRO DLNM MASS + OFFSET/resultados/figuras/individuais/indexP"
  ),
  list(
    code = "RS",
    title_state = "Rio Grande do Sul",
    input_file = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/RIO GRANDE DO SUL DLNM MASS + OFFSET/resultados/summaries/resultados_indexP_offset.RData",
    output_dir = "c:/Users/DaniLinda/Desktop/Doutorado PE/analises_individuais/DLNM MASS + OFFSET/RIO GRANDE DO SUL DLNM MASS + OFFSET/resultados/figuras/individuais/indexP"
  )
)

ylim <- c(0, 6)

for (state_cfg in states) {
  if (!file.exists(state_cfg$input_file)) {
    stop("Arquivo de resultados nao encontrado: ", state_cfg$input_file)
  }

  if (!dir.exists(state_cfg$output_dir)) {
    dir.create(state_cfg$output_dir, recursive = TRUE)
  }

  env <- new.env()
  load(state_cfg$input_file, envir = env)

  if (!exists("pred", envir = env)) {
    stop("Objeto 'pred' nao encontrado em: ", state_cfg$input_file)
  }

  pred_obj <- get("pred", envir = env)
  slice_list <- build_slice_list(pred_obj)
  slice_list_3x4 <- slice_list[1:12]
  slice_lag12 <- slice_list[[13]]

  xlim <- range(pred_obj$predvar, na.rm = TRUE)
  xticks <- pretty(xlim, n = 6)
  xticks <- xticks[xticks >= xlim[1] & xticks <= xlim[2]]

  svg_file <- file.path(state_cfg$output_dir, paste0("indexP_slices_lags_0_12_offset_", state_cfg$code, ".svg"))
  png_file <- file.path(state_cfg$output_dir, paste0("indexP_slices_lags_0_12_offset_", state_cfg$code, ".png"))
  svg_file_3x4 <- file.path(state_cfg$output_dir, paste0("indexP_slices_lags_0_11_offset_", state_cfg$code, "_3x4.svg"))
  png_file_3x4 <- file.path(state_cfg$output_dir, paste0("indexP_slices_lags_0_11_offset_", state_cfg$code, "_3x4.png"))
  svg_file_lag12 <- file.path(state_cfg$output_dir, paste0("indexP_slice_lag_12_offset_", state_cfg$code, ".svg"))
  png_file_lag12 <- file.path(state_cfg$output_dir, paste0("indexP_slice_lag_12_offset_", state_cfg$code, ".png"))
  title_text <- paste(
    "Lag-response association between high P Index values and dengue risk in",
    state_cfg$title_state
  )
  title_text_lag12 <- paste(title_text, "- Lag 12")

  save_panel(
    svg_file,
    svg,
    slice_list = slice_list,
    title_text = title_text,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    layout_matrix = matrix(
      c(
        1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
        5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8,
        9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12,
        0, 0, 0, 0, 0, 0, 13, 13, 13, 13, 0, 0, 0, 0, 0, 0
      ),
      nrow = 4,
      byrow = TRUE
    ),
    width = 12,
    height = 10,
    bg = "white"
  )
  save_panel(
    png_file,
    png,
    slice_list = slice_list,
    title_text = title_text,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    layout_matrix = matrix(
      c(
        1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4,
        5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8,
        9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12,
        0, 0, 0, 0, 0, 0, 13, 13, 13, 13, 0, 0, 0, 0, 0, 0
      ),
      nrow = 4,
      byrow = TRUE
    ),
    width = 12,
    height = 10,
    units = "in",
    res = 300,
    bg = "white"
  )

  save_panel(
    svg_file_3x4,
    svg,
    slice_list = slice_list_3x4,
    title_text = title_text,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    layout_matrix = layout_matrix_3x4,
    width = 10,
    height = 12,
    bg = "white"
  )
  save_panel(
    png_file_3x4,
    png,
    slice_list = slice_list_3x4,
    title_text = title_text,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    layout_matrix = layout_matrix_3x4,
    width = 10,
    height = 12,
    units = "in",
    res = 300,
    bg = "white"
  )

  save_single_panel(
    svg_file_lag12,
    svg,
    slice_data = slice_lag12,
    title_text = title_text_lag12,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    width = 4.5,
    height = 4,
    bg = "white"
  )
  save_single_panel(
    png_file_lag12,
    png,
    slice_data = slice_lag12,
    title_text = title_text_lag12,
    xlim = xlim,
    xticks = xticks,
    ylim = ylim,
    width = 4.5,
    height = 4,
    units = "in",
    res = 300,
    bg = "white"
  )

  message("Figura salva em:")
  message(" - ", svg_file)
  message(" - ", png_file)
  message(" - ", svg_file_3x4)
  message(" - ", png_file_3x4)
  message(" - ", svg_file_lag12)
  message(" - ", png_file_lag12)
}
