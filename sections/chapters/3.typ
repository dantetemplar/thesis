= Design and Methodology

== Research Design

To implement the performance optimizations outlined in the previous chapter, this research adopts an iterative development approach to design, develop and optimize a hardware accelerated terminal emulator. The development and research are divided into three main phases:

1. *MVP:* Building an initial baseline emulator with basic functionality, focusing on correctness, rather than performance.
2. *Optimizations incorporation:* Introducing hardware-acceleration on top of existing code, such as SIMD-based text processing and advanced GPU rendering.
3. *Performance assessment:* Conducting benchmarks of the final implementation against existing emulators, using real-world data targeting specific metrics.

This iterative approach ensures that implementation evolves through continuous testing and refinement, addressing potential bottlenecks at each stage.

== System Requirements

=== Hardware

The following are the hardware requirements for running the final implementation. It includes specific GPUs set with CPU recommendation.

- *CPU*: SIMD-capable CPU is required to take advantage of hardware accelerated text-processing algorithms for UTF-8 validation and ANSI parsing. However, serial fallback implementations exist. Therefore this is optional, but a recommended configuration, since majority of optimizations listed in this research are SIMD-based.
- *GPU*: GPU compatible with any of the following graphics API: Vulkan, Metal, D3D12, OpenGL. This API set is based on WGPU's translating capabilities of WGSL shading language.

=== Software

The following is the software configuration that was used for designing and developing proposed terminal emulator. It includes programming language choice and required libraries for interacting with hardware capabilities along with operating system.

- *Programming language:* Rust was chosen due to its raw performance and memory safety guarantees. Moreover, this language has rich infrastructure around it, providing all the required libraries for this research. This eliminates the need to resort to C-based libraries through the foreign function interface (FFI), which introduces additional performance and development overhead.
- *Libraries:*
	- *WGPU* #footnote("https://github.com/gfx-rs/wgpu") for WebGPU implementation. This is a state-of-the-art WebGPU implementation in pure Rust, used in Firefox web-browser and Deno JavaScript runtime.
	- *Portable SIMD* #footnote("https://github.com/rust-lang/portable-simd") library for cross-platform abstractions over SIMD intrinsics for the Rust programming language. It is important to note that while this project is work-in-progress, basic functionality (including support for ARM NEON and x86 AVX targets) required for this research is implemented. Moreover, once stabilized, it will become a part of standard library, making it an optimal choice for SIMD programming with Rust.
	- *simdutf8* #footnote("https://github.com/rusticstuff/simdutf8"): UTF-8 validation for Rust using SIMD extensions. This library is based _simdjson_ which itself is based on @on-demand-json @validating-utf8-in-less-than-one-instruction-per-byte-2010 @parsing-gigabytes-of-json-per-second
- *Platform:* macOS, with cross-platform testing on Linux. While Windows is not a first priority, adding support for it remains possible without extensive modifications to the code, since chosen libraries provide access to hardware capabilities in a cross-platform style. The only major difference between these systems is accessing PTY.

These configurations were chosen to balance portability, ease of development and access to hardware capabilities.

== Implementation Details

Terminal emulator anatomy typically includes the following parts:

- ANSI & DEC VT escape sequences parser (commonly referred as VT parser). This part is responsible for separating and interpreting arbitrary set of bytes as either special commands (escaped by special sequences, thus the name) @ecma-48 or plain text. Modern VT parsers typically support only UTF-8 encoded text. Input bytes come from some sort of teletype device, possibly emulated. On Linux and macOS it is called PTY (pseudotty) and ConPTY on Windows.
- Cell grid formed by executing parsed commands. These commands include cursor movement, clearing the screen, clipboard manipulation, outputting colors, bidirectional communication with the host application, etc. These commands are not strongly documented and may slightly differ from one implementation to another. As a general rule, modern terminals should be backwards compatible with xTERM @xterm implementation. The grid itself represents an internal grid of blocks and characters shaped by the backend. It should hold information about each individual cell, such as color, glyph and its attributes.
- Frontend is the final part in the terminal emulator and it is responsible for the graphical representation of the cell grid described above.

We briefly describe implemented optimizations before covering them in detail in subsequent sections.

Typical terminal emulator parsers are implemented using finite state automata, processing one byte at a time. Our implementation adopts a different strategy, using batch processing over variable slices of bytes (see @ansi-parser-pseudocode). This strategy enables us to reduce control flow branching and optimize UTF-8 validation by using SIMD-based algorithm @validating-utf8-in-less-than-one-instruction-per-byte-2010.

Frontend was based on WebGPU API implemented with WGPU, enabling cross-platform compatibility with native graphics API. Two rendering approaches were compared: partial redraw (updating only modified cells) and full-screen redraw. In our benchmarks, full-screen redraw consistently outperformed partial redraw, owing to WebGPU's requirement for complete surface updates.

Optimizing cell grid was out of the scope for this research. Cell grid implementation was taken from the Alacritty terminal and adapted for our prototype under Apache-2.0 & MIT licenses.

=== Text Processing

For optimized text-processing functionalities, the emulator incorporates several state-of-the-art algorithms and techniques to achieve exceptional performance. Work by #cite(<vt-parser>, form: "prose") served as a foundation for building correct and fast ANSI parser. It was modified to incorporate several SIMD-based optimizations targeting UTF-8 parsing and validation. 

The first difference is in batch processing parser inputs as arrays, rather than performing byte-by-byte parsing. This change opens possibilities for vectorizing several operations. One of these operations is separating UTF-8 text from escape sequences, making it easier to apply specific optimizations for each input kind.

This process can be depicted as the following pseudocode (@ansi-parser-pseudocode):

#pagebreak()

#figure(
  caption: [Detailed pseudocode for the ANSI parser’s entry point, illustrating how the parser identifies multibyte escape sequences using SIMD, validates UTF-8 in bulk, and dispatches ASCII and control-sequence data.],
  kind: "figure",
```
Procedure Advance(Parser, Performer, Bytes[])
    i ← 0
    While i < length(Bytes) do
        If Parser.nextStep = Ground then
            i ← i + AdvanceGround(Parser, Performer, Bytes[i…])
        Else If Parser.nextStep = PartialUtf8 then
            i ← i + AdvancePartialUtf8(Parser, Performer, Bytes[i…])
        Else
            ChangeState(Parser, Performer, Bytes[i])
            i ← i + 1
        End If
    End While
    Return i
End Procedure


Procedure AdvanceGround(Parser, Performer, Slice[])
	  ▷ vectorized memchr for 0x1B
    pos ← SIMD_Find(Slice, ESC)
    If pos = 0 then
        Parser.nextStep ← ChangeState
        Parser.state ← Escape
        Return 1
    End If

    prefix ← Slice[0…pos-1]
    If isASCII(prefix) then
        DispatchASCII(Performer, prefix)
    Else
		    ▷ vectorized UTF-8 decode + dispatch in bulk
        SIMD_UTF8DecodeAndDispatch(Performer, prefix)
    End If

    If pos < length(Slice) then
        Parser.nextStep ← ChangeState
        Parser.state ← Escape
        Return pos + 1
    Else
        Return pos
    End If
End Procedure
```
) <ansi-parser-pseudocode>

Note, that `ESC` in the `SIMD_Find` call is the name for the "single byte command" with byte value of `0x1B`. Mutli-byte escape sequences always start with this byte, hence the name `ESC`, while others commands are single-byte and can be parsed as a valid UTF-8 and dispatched later. Therefore, it is possible to separate regular text from special multibyte sequences using SIMD.

While logic for parsing escape sequences remains unchanged, UTF-8 is considered a special case. In addition to separating it from the control sequences, it requires validation, since it may not always be a valid UTF-8, in which case replacement character "�" should be shown on the screen. This is done on behalf of the SIMD accelerated UTF-8 validation library based on the works @on-demand-json @validating-utf8-in-less-than-one-instruction-per-byte-2010 @parsing-gigabytes-of-json-per-second.

=== Rendering

For displaying terminal grid on the screen several optimization techniques were used.

- *Batch rendering:* The emulator supports synchronized updates mechanism which allows deferring rendering intermediate states by batching commands and rendering the final state in a single GPU pass. This approach reduces unnecessary draw calls.
- *Partial redraw:* Terminal tracks modified regions between updates and renders those regions exclusively. This optimization minimizes GPU workload during partial screen updates (e.g. cursor movements). However, our benchmarks shown, that when using WebGPU such approach does not introduce rendering speedups, since WebGPU does not provide an API to access current screen surface, therefore implementing it requires holding custom surface and copying data from it to the active one on each render pass.
- *Native graphics API:* WebGPU shader translating capabilities enables utilization of native graphics API for each platform. This approach allowed maximizing GPU performance while maintaining portability. For example, when targeting macOS, WGSL shaders will be translated into Metal.

#pagebreak()

== Experimental Setup

=== Benchmarks

Performance testing involves two kinds of benchmarking workloads:

- *Synthetic:* simulated large outputs, including continuous scrolling and rapid updates, to stress test the implementation
- *Real-world:* Source code files, shell interactions, viewing logs, input latency

=== Testing environment

Several metrics contribute to making a terminal emulator "fast". The most important metrics to consider are:

- *Text throughput:* how much data the terminal can process and show on screen per specific time window. For example, outputting contents of a large file.
- *Rendering latency:* number of frames rendered to the screen per second (FPS). 

Additionally, CPU and GPU memory utilization are considered. While these metrics do not directly affect terminal speed, it is important to keep them in mind, so that our implementation will not require unneeded resources.

== Evaluation and Analysis

The evaluation criteria are based on performance gains. It includes comparing the prototype's text processing speed and rendering efficiency against baseline implementation and state-of-the-art terminal emulators (see @competitive-terminals).