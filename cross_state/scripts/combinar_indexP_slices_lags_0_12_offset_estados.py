from pathlib import Path

from PIL import Image, ImageFilter
import svgutils.transform as sg


BASE_DIR = Path(__file__).resolve().parents[2]
OUTPUT_DIR = BASE_DIR / "figuras"

STATE_CONFIGS = [
    (
        "PE",
        BASE_DIR / "PE DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_PE.svg",
        BASE_DIR / "PE DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_PE.png",
    ),
    (
        "GO",
        BASE_DIR / "GO DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_GO.svg",
        BASE_DIR / "GO DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_GO.png",
    ),
    (
        "RJ",
        BASE_DIR / "RIO DE JANEIRO DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_RJ.svg",
        BASE_DIR / "RIO DE JANEIRO DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_RJ.png",
    ),
    (
        "RS",
        BASE_DIR / "RIO GRANDE DO SUL DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_RS.svg",
        BASE_DIR / "RIO GRANDE DO SUL DLNM MASS + OFFSET" / "results" / "figuras" / "individuais" / "indexP" / "indexP_slices_lags_0_12_offset_RS.png",
    ),
]

SVG_OUTPUT = OUTPUT_DIR / "indexP_slices_lags_0_12_offset_PE_GO_RJ_RS_combined.svg"
PNG_OUTPUT = OUTPUT_DIR / "indexP_slices_lags_0_12_offset_PE_GO_RJ_RS_combined.png"
SVG_OUTPUT_VERTICAL = OUTPUT_DIR / "indexP_slices_lags_0_12_offset_PE_GO_RJ_RS_combined_vertical.svg"
PNG_OUTPUT_VERTICAL = OUTPUT_DIR / "indexP_slices_lags_0_12_offset_PE_GO_RJ_RS_combined_vertical.png"

SVG_PANEL_WIDTH = 864
SVG_PANEL_HEIGHT = 720
PNG_PANEL_WIDTH = 3600
PNG_PANEL_HEIGHT = 3000
PADDING_SVG = 36
PADDING_PNG = 150
GRID_PNG_SCALE = 5
VERTICAL_PNG_SCALE = 6
RASTER_UPSCALE = 1.5


def ensure_inputs_exist() -> None:
    missing = []
    for _, svg_path, png_path in STATE_CONFIGS:
        if not svg_path.exists():
            missing.append(str(svg_path))
        if not png_path.exists():
            missing.append(str(png_path))
    if missing:
        raise FileNotFoundError("Arquivos ausentes:\n" + "\n".join(missing))


def save_svg_figure(figure: sg.SVGFigure, output_path: Path, width: int, height: int) -> None:
    figure.save(str(output_path))
    svg_text = output_path.read_text(encoding="utf-8", errors="ignore")
    if 'width="' not in svg_text.split(">", 1)[0]:
        svg_text = svg_text.replace(
            "<svg ",
            f'<svg width="{width}" height="{height}" ',
            1,
        )
        output_path.write_text(svg_text, encoding="utf-8")


def build_svg() -> None:
    total_width = SVG_PANEL_WIDTH * 2 + PADDING_SVG * 3
    total_height = SVG_PANEL_HEIGHT * 2 + PADDING_SVG * 3

    figure = sg.SVGFigure(str(total_width), str(total_height))
    background = sg.fromstring(
        f'<rect x="0" y="0" width="{total_width}" height="{total_height}" fill="white" />'
    ).getroot()

    elements = [background]
    positions = [
        (PADDING_SVG, PADDING_SVG),
        (PADDING_SVG * 2 + SVG_PANEL_WIDTH, PADDING_SVG),
        (PADDING_SVG, PADDING_SVG * 2 + SVG_PANEL_HEIGHT),
        (PADDING_SVG * 2 + SVG_PANEL_WIDTH, PADDING_SVG * 2 + SVG_PANEL_HEIGHT),
    ]

    for (_, svg_path, _), (x, y) in zip(STATE_CONFIGS, positions):
        panel = sg.fromfile(str(svg_path)).getroot()
        panel.moveto(x, y)
        elements.append(panel)

    figure.append(elements)
    save_svg_figure(figure, SVG_OUTPUT, total_width, total_height)


def build_png() -> None:
    panel_width = int(PNG_PANEL_WIDTH * RASTER_UPSCALE)
    panel_height = int(PNG_PANEL_HEIGHT * RASTER_UPSCALE)
    padding = int(PADDING_PNG * RASTER_UPSCALE)
    total_width = panel_width * 2 + padding * 3
    total_height = panel_height * 2 + padding * 3

    canvas = Image.new("RGB", (total_width, total_height), "white")
    positions = [
        (padding, padding),
        (padding * 2 + panel_width, padding),
        (padding, padding * 2 + panel_height),
        (padding * 2 + panel_width, padding * 2 + panel_height),
    ]

    for (_, _, png_path), (x, y) in zip(STATE_CONFIGS, positions):
        panel = Image.open(png_path).convert("RGB")
        panel = panel.resize((panel_width, panel_height), Image.Resampling.LANCZOS)
        panel = panel.filter(ImageFilter.UnsharpMask(radius=1.2, percent=110, threshold=2))
        canvas.paste(panel, (x, y))

    canvas.save(PNG_OUTPUT, dpi=(300, 300))


def render_png_from_svg(
    svg_path: Path,
    png_path: Path,
    base_width: int,
    base_height: int,
    scale: int,
) -> None:
    import cairosvg

    cairosvg.svg2png(
        url=str(svg_path),
        write_to=str(png_path),
        output_width=base_width * scale,
        output_height=base_height * scale,
    )


def build_svg_vertical() -> None:
    total_width = SVG_PANEL_WIDTH + PADDING_SVG * 2
    total_height = SVG_PANEL_HEIGHT * 4 + PADDING_SVG * 5

    figure = sg.SVGFigure(str(total_width), str(total_height))
    background = sg.fromstring(
        f'<rect x="0" y="0" width="{total_width}" height="{total_height}" fill="white" />'
    ).getroot()

    elements = [background]
    positions = [
        (PADDING_SVG, PADDING_SVG),
        (PADDING_SVG, PADDING_SVG * 2 + SVG_PANEL_HEIGHT),
        (PADDING_SVG, PADDING_SVG * 3 + SVG_PANEL_HEIGHT * 2),
        (PADDING_SVG, PADDING_SVG * 4 + SVG_PANEL_HEIGHT * 3),
    ]

    for (_, svg_path, _), (x, y) in zip(STATE_CONFIGS, positions):
        panel = sg.fromfile(str(svg_path)).getroot()
        panel.moveto(x, y)
        elements.append(panel)

    figure.append(elements)
    save_svg_figure(figure, SVG_OUTPUT_VERTICAL, total_width, total_height)


def build_png_vertical() -> None:
    panel_width = int(PNG_PANEL_WIDTH * RASTER_UPSCALE)
    panel_height = int(PNG_PANEL_HEIGHT * RASTER_UPSCALE)
    padding = int(PADDING_PNG * RASTER_UPSCALE)
    total_width = panel_width + padding * 2
    total_height = panel_height * 4 + padding * 5

    canvas = Image.new("RGB", (total_width, total_height), "white")
    positions = [
        (padding, padding),
        (padding, padding * 2 + panel_height),
        (padding, padding * 3 + panel_height * 2),
        (padding, padding * 4 + panel_height * 3),
    ]

    for (_, _, png_path), (x, y) in zip(STATE_CONFIGS, positions):
        panel = Image.open(png_path).convert("RGB")
        panel = panel.resize((panel_width, panel_height), Image.Resampling.LANCZOS)
        panel = panel.filter(ImageFilter.UnsharpMask(radius=1.2, percent=110, threshold=2))
        canvas.paste(panel, (x, y))

    canvas.save(PNG_OUTPUT_VERTICAL, dpi=(300, 300))


def main() -> None:
    OUTPUT_DIR.mkdir(exist_ok=True)
    ensure_inputs_exist()
    build_svg()
    build_svg_vertical()

    try:
        render_png_from_svg(
            SVG_OUTPUT,
            PNG_OUTPUT,
            SVG_PANEL_WIDTH * 2 + PADDING_SVG * 3,
            SVG_PANEL_HEIGHT * 2 + PADDING_SVG * 3,
            GRID_PNG_SCALE,
        )
        render_png_from_svg(
            SVG_OUTPUT_VERTICAL,
            PNG_OUTPUT_VERTICAL,
            SVG_PANEL_WIDTH + PADDING_SVG * 2,
            SVG_PANEL_HEIGHT * 4 + PADDING_SVG * 5,
            VERTICAL_PNG_SCALE,
        )
    except Exception:
        # Fallback keeps figure generation working even if SVG rasterization fails.
        build_png()
        build_png_vertical()

    print(f"Figura SVG salva em: {SVG_OUTPUT}")
    print(f"Figura PNG salva em: {PNG_OUTPUT}")
    print(f"Figura SVG vertical salva em: {SVG_OUTPUT_VERTICAL}")
    print(f"Figura PNG vertical salva em: {PNG_OUTPUT_VERTICAL}")


if __name__ == "__main__":
    main()
