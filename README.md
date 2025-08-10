rtlsdr-odin
============

High‑performance, thin, idiomatic Odin bindings for `librtlsdr` (RTL2832U / RTL-SDR USB dongles). Focus: zero fluff, immediate samples to your buffers, sync & async paths, ergonomic iteration while staying 1:1 with the C API.

> warning: only testing on macOS.

Why
----
You want raw IQ from a $20 dongle inside an Odin app (DSP, spectrum, decoding, visualization) without detouring through C glue. This repo gives you:

* Direct foreign imports (no wrappers hiding power)
* Sync + async streaming
* Full device + tuner control (freq, gains, PPM, direct sampling, offset tuning, IF gains, AGC)
* Works on macOS, Linux, (Should work on Windows with the included libraries, but haven't tested)

Status
------
Core enumeration, open/close, frequency, sample rate, gain & streaming calls are bound. (Everything in the public header that matters to realtime IQ capture.)

Install Prerequisites
---------------------
macOS (Homebrew):
```
brew install librtlsdr odin
```
Linux (Debian/Ubuntu):
```
sudo apt install rtl-sdr odin
```
Arch:
```
sudo pacman -S rtl-sdr odin
```
Windows:
NOT TESTED

Precompiled libraries on in `rtlsdr/windows/x86` and `rtlsdr/windows/x64`.
If you want different ones, just replace them with your own.

1. Install Zadig drivers for the dongle (WinUSB)


Quick Start (Sync Read)
-----------------------
Minimal example (see `examples/get_samples` for a runnable variant):
```odin
package open_rtlsdr
import "core:fmt"
import "core:time"

import rtlsdr "../../rtlsdr"

main :: proc () {
    using rtlsdr

    num_devices := rtlsdr_get_device_count()
    if num_devices == 0 {
        fmt.println("No RTL-SDR devices found. Is it plugged in?")
        return
    }

    dev: ^rtlsdr_dev
    device_id: u32 = 0
    ok := rtlsdr_open(&dev, device_id)
    if ok != 0 {
        fmt.println("Failed to open device", device_id)
        return
    } else {
        fmt.println("Opened device", device_id, ":", rtlsdr_get_device_name(device_id))
    }

    rtlsdr_set_center_freq(dev, 101.1e6)
    rtlsdr_set_sample_rate(dev, 1024000)
    rtlsdr_set_agc_mode(dev, 0)
    rtlsdr_reset_buffer(dev)
    
    // define buffer and recv data
    buffer_size: i32 = 1024 * 16  // 16KB buffer
    buffer := make([]u8, buffer_size)
    defer delete(buffer)
    
    bytes_read: i32
    read_result := rtlsdr_read_sync(dev, raw_data(buffer), buffer_size, &bytes_read)
    
    fmt.println("Read result code:", read_result)
    fmt.println("Bytes read:", bytes_read)

    if read_result == 0 {
        fmt.println("Successfully read", bytes_read, "bytes from RTL-SDR")
        // Process the data in buffer here
        fmt.println("First few samples:", buffer[:min(10, len(buffer))])
    } else {
        fmt.println("Failed to read from device, error:", read_result)
    }
    
    ok = rtlsdr_close(dev)
}
```

**Example Output:**
```
Found Rafael Micro R828D tuner
RTL-SDR Blog V4 Detected
Opened device 0 : Generic RTL2832U OEM
Read result code: 0
Bytes read: 16384
Successfully read 16384 bytes from RTL-SDR
First few samples: [124, 127, 124, 127, 124, 126, 124, 126, 124, 126]
First few samples (converted to f32): [-0.027450979, -0.0039215684, -0.027450979, -0.0039215684, -0.027450979, -0.011764705, -0.027450979, -0.011764705, -0.027450979, -0.011764705]   
```

Async Streaming
---------------
Asynchronous mode spawns internal worker threads in the driver and invokes your callback continuously until cancelled:
```odin
read_cb :: proc "c" (data: ^u8, length: u32, ctx: rawptr) {
	// length bytes: interleaved unsigned IQ (I,Q,I,Q,...)
}

// After configuring the device:
rtlsdr.rtlsdr_read_async(dev^, read_cb, nil, 0, 0) // 0 => driver defaults (e.g. 32 x 16k)

// Elsewhere to stop:
rtlsdr.rtlsdr_cancel_async(dev^)
```
Use `rtlsdr_wait_async` if you set up the callback from another thread and want to block until start.

API Reference
-------------

**Device Management:**
* `rtlsdr_get_device_count() -> u32` - Get number of connected RTL-SDR devices
* `rtlsdr_get_device_name(index: u32) -> cstring` - Get device name string by index
* `rtlsdr_open(dev: ^^rtlsdr_dev, index: u32) -> i32` - Open device by index
* `rtlsdr_close(dev: ^rtlsdr_dev) -> i32` - Close device

**Hardware Info:**
* `rtlsdr_get_usb_strings(dev: ^rtlsdr_dev, vendor: ^u8, product: ^u8, serial: ^u8) -> i32` - Get USB device strings
* `rtlsdr_read_eeprom(dev: ^rtlsdr_dev, data: ^u8, offset: u8, len: u16) -> i32` - Read EEPROM data
* `rtlsdr_write_eeprom(dev: ^rtlsdr_dev, data: ^u8, offset: u8, len: u16) -> i32` - Write EEPROM data
* `rtlsdr_get_xtal_freq(dev: ^rtlsdr_dev, rtl_freq: ^u32, tuner_freq: ^u32) -> i32` - Get crystal frequencies
* `rtlsdr_set_xtal_freq(dev: ^rtlsdr_dev, rtl_freq: u32, tuner_freq: u32) -> i32` - Set crystal frequencies

**Frequency Control:**
* `rtlsdr_set_center_freq(dev: ^rtlsdr_dev, freq: u32) -> i32` - Set center frequency in Hz
* `rtlsdr_get_center_freq(dev: ^rtlsdr_dev) -> u32` - Get current center frequency
* `rtlsdr_set_freq_correction(dev: ^rtlsdr_dev, ppm: i32) -> i32` - Set frequency correction in PPM
* `rtlsdr_get_freq_correction(dev: ^rtlsdr_dev) -> i32` - Get frequency correction

**Sample Rate:**
* `rtlsdr_set_sample_rate(dev: ^rtlsdr_dev, rate: u32) -> i32` - Set sample rate in Hz
* `rtlsdr_get_sample_rate(dev: ^rtlsdr_dev) -> u32` - Get current sample rate
* `rtlsdr_reset_buffer(dev: ^rtlsdr_dev) -> i32` - Reset internal buffers

**Gain Control:**
* `rtlsdr_get_tuner_gains(dev: ^rtlsdr_dev, gains: ^i32) -> i32` - Get supported gain values
* `rtlsdr_set_tuner_gain_mode(dev: ^rtlsdr_dev, manual: i32) -> i32` - Enable/disable manual gain
* `rtlsdr_set_tuner_gain(dev: ^rtlsdr_dev, gain: i32) -> i32` - Set tuner gain
* `rtlsdr_get_tuner_gain(dev: ^rtlsdr_dev) -> i32` - Get current tuner gain
* `rtlsdr_set_agc_mode(dev: ^rtlsdr_dev, on: i32) -> i32` - Enable/disable AGC

**Advanced Settings:**
* `rtlsdr_set_direct_sampling(dev: ^rtlsdr_dev, on: i32) -> i32` - Enable direct sampling mode
* `rtlsdr_set_offset_tuning(dev: ^rtlsdr_dev, on: i32) -> i32` - Enable offset tuning

**Data Streaming:**
* `rtlsdr_read_sync(dev: ^rtlsdr_dev, buf: rawptr, len: i32, n_read: ^i32) -> i32` - Synchronous read
* `rtlsdr_read_async(dev: ^rtlsdr_dev, cb: rtlsdr_read_async_cb_t, ctx: rawptr, buf_num: u32, buf_len: u32) -> i32` - Start async reading
* `rtlsdr_cancel_async(dev: ^rtlsdr_dev) -> i32` - Stop async reading
* `rtlsdr_wait_async(dev: ^rtlsdr_dev, cb: rtlsdr_read_async_cb_t, ctx: rawptr) -> i32` - Wait for async completion

**Data Types:**
* `rtlsdr_dev` - Opaque device handle
* `rtlsdr_read_async_cb_t :: proc "c" (buf: ^u8, len: u32, ctx: rawptr)` - Async callback type

**Utility Functions:**
* `utils.mhz_to_hz(freq: f64) -> u32` - Convert MHz to Hz
* `utils.hz_to_mhz(freq: u32) -> f64` - Convert Hz to MHz  
* `utils.mhz_to_khz(freq: f64) -> f64` - Convert MHz to kHz
* `utils.khz_to_mhz(freq: u32) -> f64` - Convert kHz to MHz
* `utils.u8_to_f32(input: ^u8, len: u32) -> []f32` - Convert interleaved u8 IQ data to normalized f32 array [-1, 1]

Typical Workflow
----------------
1. Enumerate devices & pick index
2. `rtlsdr_open`
3. Configure: freq -> sample rate -> PPM -> gain mode/gain -> direct/offset options
4. `rtlsdr_reset_buffer`
5. Start sync loop OR async callback
6. Process IQ (FFT, demod, etc.)
7. Optional: adjust gain/frequency live
8. Cancel async (if used) & `rtlsdr_close`

Error Handling
--------------
Driver functions return 0 on success (or positive values for queries) and negative on error. Keep it simple:
```odin
if rtlsdr.rtlsdr_set_center_freq(dev^, freq) < 0 { /* handle */ }
```
You can wrap return codes in your own helper for nicer error messages if desired.

Performance Notes
-----------------
* Use async for sustained high rates; it pre-fills multiple buffers.
* Keep your callback lean: push to a lock-free ring or channel for downstream DSP.
* Batch FFTs: convert unsigned IQ (0..255) -> float centered at 0 via `(f32(x)-127.5)/127.5`.
* Larger synchronous reads reduce syscall overhead but increase latency.


Building Examples
-----------------
From repo root:
```
odin build examples/get_samples -out:build/get_samples
./build/get_samples
```
Or use provided script (if any) / copy into your project.

Using in your Project
----------------------
Copy the `rtlsdr` directory into your project. Reference it in your Odin code:
```odin
import "path/to/rtlsdr"
```
Thats it.

Data Format
-----------
Unsigned 8-bit interleaved IQ: [I0, Q0, I1, Q1, ...]. Convert to floats before DSP. Expect DC spike at center; apply DC removal / window / FFT.

License
-------
These bindings: MIT (add MIT file if distributing). Underlying `librtlsdr` is LGPL;

Credits
-------
RTL-SDR authors & Odin language community.

Have fun pulling RF out of thin air.

