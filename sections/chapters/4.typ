#import "/lib.typ": todo

= Implementation and Results

Results were validated through a set of reproducible experiments over varied data. Scripts and code are available online: #link("https://github.com/metafates/saiga")

== Hardware and Software

We used an Apple M1 SOC in our tests. We summarize the characteristics of our hardware platform in @hardware.

Our software was written using Rust 1.84. We used rustc compiler with `-Ctarget-cpu=native -Ccodegen-units=1 -Clto=fat` optimization flags, to ensure our build is able to use all available capabilities of the target hardware.

Alacritty and Wezterm were chosen as baselines due to their dominance in open-source Rust terminal ecosystem and their contrasting design philosophies (batch vs. byte parsing). They are both mature and well-optimized. They were initially released in 2017 and 2019 respectively. See @competitive-terminals.

#figure(
  table(
    columns: (1fr, 1fr, 2fr, 1fr),
    inset: 10pt,
    align: horizon + center,
    table.header(
      [SoC], [Max. Frequency], [Microarchitecture], [Memory],
    ),
    [Apple M1], [3.2 GHz], [Firestorm & Icestorm (ARM64, 2020)], [LPDDR4X],
  ),
  caption: [Hardware specifications of the Apple M1 platform used for all performance experiments],
) <hardware>

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    table.header(
      [Name], [Snapshot], [Link]
    ),
    [Saiga], [March 10th 2025], [#link("https://github.com/metafates/saiga")],
    
    [Alacritty], [0.15.1], [#link("https://github.com/alacritty/alacritty")],
    
    [Wezterm], [February 3rd 2024], [#link("https://github.com/wezterm/wezterm")],
  ),
  caption: [List of terminal emulator implementations used for performance comparison.]
) <competitive-terminals>

== ANSI Parsing

The three terminal emulators -- Saiga (our prototype), Alacritty, and Wezterm - are based on finite state automata (FSA) described by @vt-parser for parsing ANSI control sequences. However, while Wezterm does not deviate from the baseline FSA implementation, Saiga and Alacritty introduce unique optimization. These optimizations yield major performance improvements, as shown by the benchmark results in @vte-benchmark-results.

- *Saiga* uses input batch processing with SIMD-accelerated UTF-8 validation. First, it processes input in variable _batches_ of bytes, reducing per-byte overhead by operating on contiguous blocks of data. This approach reduces function calls, minimizes branch mispredictions, and improves cache locality. One more advantage of this approach is that it opens further possibilities for optimizing processing, since we identify which bytes we will need to handle next and operate on chunks of data. This leads us to the second optimization Saiga uses - SIMD based UTF-8 validation, developed by @validating-utf8-in-less-than-one-instruction-per-byte-2010. By validating several bytes simultaneously Saiga reduces validation latency - one of the major bottlenecks for VT parsers. The FSA transitions remain stateful but operate on pre-validated batches, allowing the parser to focus on control sequence logic without interleaving validation checks. This design is  effective for datasets, such as `unicode` or `missing_glyphs`, where multi-byte UTF-8 characters dominate and require frequent validation.

- *Alacritty* uses batch processing with scalar validation. It similarly processes input in batches, avoiding byte-by-byte overhead, but uses scalar UTF-8 validation algorithm. This creates a linear dependence on input size and validation time, which partly neglects optimizations that batch processing introduce. For example, in the `unicode` benchmark, Alacritty’s throughput (1.05 GB/s) is 2.34 times slower than Saiga’s SIMD approach with 2.33 GB/s throughput. Its FSA transitions are similar to Saiga’s, resulting comparable parsing efficiency for non-textual inputs.

- *Wezterm* adopts a traditional byte-by-byte processing algorithm, invoking FSA for each individual byte. While the FSA itself is similar, the lack of optimizations described above leads to worse performance across all benchmarks as seen further in @vte-benchmark-results.

=== Datasets

Parsing speed is dependent on the content of the input data. For a fair assessment, we chose a wide range of datasets. See @vte-datasets-stats for detailed statistics concerning the chosen files.

#figure(
  caption: [Dataset statistics. Printed stands for plain text. Executed are C0 commands. OSC, CSI & ESC stands for the number of dispatched multi-byte sequences for each type],
  table(
    columns: 4,
    table.header(
      [Name], [Printed], [Executed], [Size],
    ),
    [ascii_all], [79], [32], [128],
    [ascii_printable], [95], [0], [95],
    [cursor_motion], [83200], [83200], [721 kB],
    [dense_cells], [83200], [83227], [2.2 MB],
    [light_cells], [83200], [27], [83 kB],
    [medium_cells], [69936], [19678], [178 kB],
    [missing_glyphs], [1286400], [202], [1.3 MB],
    [sync_medium_cells], [69936], [20602], [186 kB],
    [unicode], [46606], [2], [138 kB],
    [no_print], [0], [200000], [910 kB]
  )
) <vte-datasets-stats>

While mostly synthetic, these datasets reflect extreme cases observed in real workloads:

- `unicode`: Heavy I/O in multilingual environments (e.g., logging servers).
- `no_print`: CLI tools, such as top or kubectl, that prioritize control sequences.

Benchmarks were sourced from Alacritty's vtebench #footnote[https://github.com/alacritty/vtebench] to ensure comparability.

=== Running Time Distribution

In @vte-benchmark-results we present the VT parser benchmarks results for each dataset (@vte-datasets-stats).

Our experiments reveal different performance profiles across three terminal emulators. Our implementation (saiga) shows consistently better throughput in text-heavy workloads, in particular for datasets dominated by ASCII or Unicode characters (`ascii_printable` and `unicode` benchmarks), where SIMD-accelerated batch processing yielded a 2.4–2.6× throughput improvement over Alacritty, which uses batch processing without SIMD UTF-8 validation, and 4.8-9.2× over Wezterm parser, which uses byte-by-byte parser without further hardware optimizations. These results highlight the advantages of hardware acceleration for VT parsers, as Saiga’s implementation minimizes per-byte processing overhead -- a critical factor given how much text terminals are processing. The `missing_glyphs` benchmark further outlines this divergence: Saiga processes 2.59 GB/s compared to Alacritty's 1.44 GB/s, despite both implementations are based on batch processing technique.

In control sequence-intensive workloads (`cursor_motion`, `dense_cells`), where parsing efficiency is not dominated by SIMD optimizations, Saiga maintains narrower but consistent leads (on average 4-18% faster than Alacritty). However, both implementations outperform Wezterm by 40-50%. This suggests that batch processing alone - common to both Saiga and Alacritty - provides baseline acceleration for command parsing, compared to byte-by-byte processing, but Saiga’s architectural optimizations, such as reduced branching and branch mispredications, yield incremental gains.

Expanding further on control sequence workloads, the `no_print` benchmark, exclusively stressing OSC, CSI and ESC sequences, isolates plain text parsing from other targets. Here, Saiga and Alacritty exhibit similar performance at 337 and 340 MB/s respectively. This parity implies comparable command parsing efficiency between the batch processor, while Wezterm lags at 148 MB/s, confirming the cost of non-batch parsing.

#pagebreak()

#figure(
  caption: [ANSI Parsing Throughput rounded to MB _(higher is better)_.
  Median time per dataset _(lower is better)_],
  table(
    columns: 4,
    table.header(
      [Dataset], [Terminal], [Median Time], [Throughput],
    ),
    table.cell(rowspan: 3, align: horizon)[ascii_all],
    [alacritty], [139.35 ns], [918 MB/s],
    [saiga], [85.504 ns], [1.5 GB/s],
    [wezterm], [287.89 ns], [444 MB/s],

    table.cell(rowspan: 3, align: horizon)[ascii_printable],
    [alacritty], [84.158 ns], [1.1 GB/s],
    [saiga], [39.049 ns], [2.4 GB/s],
    [wezterm], [186.21 ns], [510 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[cursor_motion],
    [alacritty], [1.9165 ms], [376 MB/s],
    [saiga], [1.7876 ms], [403 MB/s],
    [wezterm], [4.2954 ms], [168 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[dense_cells],
    [alacritty], [5.3926 ms], [416 MB/s],
    [saiga], [4.4848 ms], [501 MB/s],
    [wezterm], [9.6800 ms], [232 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[light_cells],
    [alacritty], [58.178 µs], [1.4 GB/s],
    [saiga], [33.047 µs], [2.5 GB/s],
    [wezterm], [160.77 µs], [518 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[medium_cells],
    [alacritty], [437.68 µs], [407 MB/s],
    [saiga], [407.86 µs], [438 MB/s],
    [wezterm], [910.35 µs], [196 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[missing_glyphs],
    [alacritty], [891.34 µs], [1.4 GB/s],
    [saiga], [497.82 µs], [2.6 GB/s],
    [wezterm], [2.4737 ms], [520 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[sync_medium_cells],
    [alacritty], [458.56 µs], [405 MB/s],
    [saiga], [427.20 µs], [435 MB/s],
    [wezterm], [958.62 µs], [194 MB/s],

    table.cell(rowspan: 3, align: horizon)[unicode],
    [alacritty], [131.77 µs], [1 GB/s],
    [saiga], [59.214 µs], [2.3 GB/s],
    [wezterm], [546.40 µs], [253 MB/s],
    
    table.cell(rowspan: 3, align: horizon)[no_print],
    [alacritty], [2.6711 ms], [341 MB/s],
    [saiga], [2.6962 ms], [338 MB/s],
    [wezterm], [6.1493 ms], [148 MB/s],
  )
) <vte-benchmark-results>

#pagebreak()

Mixed workloads, such as `medium_cells` and `sync_medium_cells`, demonstrate that Saiga maintains 7-10% throughput lead over Alacritty. The datasets combine moderate text volumes with frequent control sequences, allowing Saiga to use SIMD UTF-8 validation while benefiting from batch-parsed command processing. The stability of this advantage for both synchronized and unsynchronized variants suggests resilience to synchronization overhead (in `sync_medium_cells`).

Architecturally, the results validate three key design principles:

1. *Batch processing* provides fundamental throughput gains over byte-by-byte parsing, as evidenced by Alacritty’s consistent 2-3x speedups over Wezterm across all benchmarks.
2. *SIMD integration* enhances batch processing for text-heavy workloads, with Saiga achieving superlinear speedups over Alacritty where UTF-8 validation dominates, resulting 2.4-2.6x performance improvements.
3. *Control sequences optimization* remains important even with batch processing. While Saiga provides consistent incremental leads in command-heavy workloads, likely due to branching optimizations, utilizing SIMD for parsing control sequences could result significant speedups, as shown by benchmarks with plain text-heavy data.

These findings point to Saiga's VT parser hybrid architecture, combining batch processing baseline efficiency with hardware acceleration through SIMD UTF-8 validation. Our implementation avoids common vectorization pitfalls, such as throughput degradation on non-vectorizable data. This dual optimization suggests broad applicability across terminal emulation workloads. Future work could explore SIMD utilization for parsing commands, potentially pushing the boundaries of efficient terminal emulation even further.

Results are specific to ARM64's memory latency and SIMD throughput. Performance of X86 may vary due to different vectorization overhead.

== Rendering to the screen

To evaluate rendering speed for these terminals, we conducted benchmarks using the following approaches:

- High-frequency DOOM-fire animation #footnote[https://github.com/const-void/DOOM-fire-zig]. It stress-tests real-time rendering for animations (e.g., progress bars, REPL UIs). This benchmark, modifying approximately 4800 cells per frame in a 120×40 terminal grid, measures frames per second rendered for each terminal.
- Bulk `cat` execution of a large file into standard output. It emulates bulk output scenarios (e.g., log dumps, CI/CD pipelines). The results show how parsing strategies, rendering implementations and GPU API constraints interact across Saiga, Alacritty and Wezterm. 

Both Saiga (our implementation) and Wezterm use WebGPU, which compiles to Metal on macOS, while Alacritty use OpenGL 4.1.

#pagebreak()

#figure(
  caption: [DOOM-fire benchmark. Hybrid Alacritty uses Saiga's VT parse],
  table(
    columns: 5,
    align: horizon,
    table.header(
      [Terminal], [Application FPS], [OS FPS], [Rendering Backend], [Partial redraw]
    ),
    [Alacritty], [484], [60], [OpenGL], [yes],
    [Hybrid Alacritty], [570], [60], [OpenGL], [yes],
    [Saiga], [450], [38], [WebGPU], [no],
    [Saiga], [443], [38], [WebGPU], [yes],
    [Wezterm], [736], [36], [WebGPU], [no],
  ),
)

Alacritty, using partial screen redraws achieves a stable 60 FPS on 60 HZ screen due to vertical synchronization, as observed by the macOS developer tools with Quartz Debug and 484 FPS reported by the application. As an experiment, we were able to substitute Alacritty's VT parser with our optimized implementation, which provides a compatible API. It resulted 17.8% application FPS boost to 570, while preserving the same stable 60 FPS for the OS window. Replacing Alacritty's parser with Saiga's isolates parsing efficiency from rendering, confirming that achieved gain is attributable solely to reduced CPU contention.

By contrast, Saiga showed worse performance. Saiga, without partial screen redraws, reported 450 FPS in application, but delivered 38 FPS to the OS window. Using partial updates resulted in worse performance, at 443 and 33 FPS in application and OS respectively. WebGPU's security model prohibits direct surface access, forcing Saiga to implement partial redraws via auxiliary buffers. This introduces extensive copying on each frame, therefore eliminating the benefits of partial screen updates.

Wezterm's result of 736 application FPS paired with 36 OS FPS suggests a strategy of frame queuing without synchronization.

The `cat` benchmark, which processes a 100MB ASCII file, stresses the renderer with bulk text throughput. The benchmark can be reproduced with the following BASH script on macOS (@testdata-generation):

#figure(
  caption: [BASH script to generate 100 MB file of random bytes.],
  kind: "figure",
```bash
base64 --input=/dev/urandom | head -c 100000000 > 100mb.txt
time cat 100mb.txt
```
) <testdata-generation>

#figure(
  caption: [Text throughput benchmark],
  table(
    columns: 2,
    table.header(
      [Terminal], [Time (seconds)],
    ),
    [Alacritty], [1.67],
    [Hybrid Alacritty], [1.25],
    [Saiga], [2.38],
    [Saiga (partial redraw)], [2.78],
    [Wezterm], [3.4],
  )
)

Alacritty, utilizing Saiga’s VT parser, completes the task in 1.25 seconds - 25% faster than its original implementation with 1.67 seconds. Reverting Alacritty to byte-by-byte parsing degrades performance to 1.75 seconds - 4.8% worse than original - proving, that parsing inefficiency propagates downstream regardless of the rendering backend.

Saiga’a implementation with WebGPU reveals its limitation. Despite sharing the same code, expect for the frontend, as the hybrid Alacritty variant, Saiga requires 2.38 seconds - 90% slower, due to WebGPU’s surface-copy overhead as described above. Wezterm’s performance further illustrates this, resulting 3.4 seconds runtime with its byte-by-byte parser and WebGPU frontend.

== Summary

This study mostly focuses on CPU-bound parsing and GPU rendering. Real-world terminal performance also depends on GPU drivers, I/O scheduling, and shell integration—factors beyond this paper's scope.

Our approach of parsing text in variable-length batches and using SIMD instructions for UTF-8 validation proves itself effective for handling small, medium and large volumes of data. In benchmarks, such as `unicode` or `missing_glyphs`, our proposed implementation outperforms other state-of-the-art parsers by 2-3x, showing that modern hardware, when used properly, can drastically improve processing speed. However, it is important that the rendering system is able to keep up with it.

Alacritty demonstrates this balance well. By integrating Saiga's efficient VT parser with Alacritty's code, which uses OpenGL for rendering, it achieves the best overall performance among other variations tested in our research. For example, hybrid Alacritty implementation achieves a 18% better application FPS as shown by the DOOM-fire benchmark compared to the baseline Alacritty implementation.

WebGPU, used by Saiga and Wezterm, introduces challenges when targeting terminal-specific optimizations. While it offers cross platform compatibility and great performance by compiling its own shading language, WGSL, into native graphics API for each of the supported OS, its security rules force full-screen redraws for every update, creating bottleneck in our specific use-case. Saiga's parser is able to process text quickly; however WebGPU's overhead limits visible performance, resulting 38 FPS for the OS window in the DOOM-fire benchmark. Wezterm shows similar performance with 36 FPS, despite using much slower VT parser implementation, suggesting that rendering to the screen with WebGPU might be the bottleneck in this case.

While WebGPU limits Saiga’s rendering performance, its cross-platform benefits (Metal/Vulkan/DX12 support) make it viable for non-latency-sensitive applications. Future work should explore Vulkan/Metal-native rendering for Saiga while retaining WebGPU for cross-platform fallback.