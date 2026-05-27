# Thesis (Typst)

Bachelor thesis source in [Typst](https://typst.app/).

The document template (layout, title page conventions, typography) belongs to **Innopolis University**.

## Prerequisites

- [Typst](https://github.com/typst/typst/releases) on your `PATH` (`typst --version`).
- **Times New Roman** installed system-wide (body text and title export from LibreOffice).
- **Git LFS** if you clone PDFs tracked by LFS (`git lfs install` once per machine).

## Main document

Entry file (repository root):

`Interactive Assistant for Timetable Editing and Optimization in Educational Institutions.typ`

Run from this repository (the directory that contains this README) so imports and assets resolve the same way as on CI:

```bash
typst watch "Interactive Assistant for Timetable Editing and Optimization in Educational Institutions.typ"
```

It will watch for changes and rebuild the PDF automatically.

## Title page (`title.pdf`)

Prepare your title page by yourself and export it to `title.pdf`, it will be embedded in the main document. For example, I have used provided [Title Page 2026.docx](Title%20Page%202026.docx).

## IDE: Tinymist

For editing in **VS Code** or **Cursor**, install the **[Tinymist](https://github.com/Myriad-Dreamin/tinymist)** extension. It provides syntax highlighting, jump-to-definition, preview, and can run the compiler using the same root as your project.

Open main file in IDE and run "Typst: Pin the Main File to the Currently Open Document" command, via Ctrl+Shift+P.


## Repository layout (short)

| Path | Role |
|------|------|
| `Interactive Assistant … .typ` | Main entry |
| `template.typ` | Global styles, headers, bibliography |
| `Title Page 2026.docx` | Title page source (edit here) |
| `title.pdf` | Exported title page embedded in the thesis (Git LFS) |
| `sections/` | Body text: see tree below |
| `figures/` | Raster/SVG assets referenced from chapters |
| `ref.bib`, `ieee.csl` | Bibliography |

`sections/` tree:

```text
sections/
├── abstract.typ
├── bibliography.typ
├── contents.typ
├── chapters/
│   ├── 1.typ
│   ├── 2.typ
│   ├── 3.typ
│   ├── 4.typ
│   └── 5.typ
└── list/
    ├── figures.typ
    └── tables.typ
```
