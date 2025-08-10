package utils
// FILE SUMMARY: Frequency unit conversions, rounding helper, and u8 normalization
// utilities used by radio setup & display logic.

// NOTE: Utility module untouched by FFT algorithm choices; potential future:
// add fused scaling/window helpers to reduce passes.

import "core:math"

mhz_to_hz :: proc "contextless" (freq: f64) -> u32 {
    return u32(math.round(freq * 1_000_000))
}

hz_to_mhz :: proc "contextless" (freq: u32) -> f64 {
    return f64(freq) / 1_000_000 
}

mhz_to_khz :: proc "contextless" (freq: f64) -> f64 {
    return freq * 1_000.0
}

khz_to_mhz :: proc "contextless" (freq: u32) -> f64 {
    return f64(freq) / 1_000.0
}

// Convert interleaved u8 IQ data to f32 array and normalize to [-1, 1]
u8_to_f32 :: proc (input: ^u8, len: u32) -> []f32 {
    output := make([]f32, len)
    data := ([^]u8)(input)
    for i in 0..<len {
        output[i] = (f32(data[i]) / 127.5) - 1.0 // Normalize to [-1, 1]
    }
    return output
}