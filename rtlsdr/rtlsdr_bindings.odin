package rtlsdr

// System library import (name is just the short SONAME without prefixes/suffixes)
// On macOS this resolves to librtlsdr.dylib, on Linux to librtlsdr.so, on Windows to rtlsdr.dll

when ODIN_OS == .Windows {
    when ODIN_ARCH == .x86 {
        foreign import rtlsdr "windows/x86/rtlsdr.lib"
    } else {
        foreign import rtlsdr "windows/x64/rtlsdr.lib"
    }
} else {
    foreign import rtlsdr "system:rtlsdr"
}



// Opaque struct - we don't need to know the internal structure
rtlsdr_dev :: struct {}

// Types
rtlsdr_read_async_cb_t :: proc "c" (buf: ^u8, len: u32, ctx: rawptr)

// Core C header import. Make sure the system has development headers installed
// (e.g. brew install librtlsdr, apt install librtlsdr-dev, pacman -S rtl-sdr, etc.)
@(default_calling_convention="c")
foreign rtlsdr {

    // ---------- Device enumeration ----------
    rtlsdr_get_device_count :: proc() -> u32 ---
    rtlsdr_get_device_name  :: proc(index: u32) -> cstring ---
    rtlsdr_get_device_usb_strings :: proc(index: u32, manufact: ^u8, product: ^u8, serial: ^u8) -> i32 ---
    rtlsdr_get_index_by_serial :: proc(serial: cstring) -> i32 --- // returns -1 on error

    // // ---------- Open / close ----------
    rtlsdr_open  :: proc(dev_out: ^^rtlsdr_dev, index: u32) -> i32 ---
    rtlsdr_close :: proc(dev: ^rtlsdr_dev) -> i32 ---

    // // ---------- Crystal / EEPROM / USB strings ----------
    rtlsdr_set_xtal_freq :: proc(dev: ^rtlsdr_dev, rtl_freq_hz: u32, tuner_freq_hz: u32) -> i32 ---
    rtlsdr_get_xtal_freq :: proc(dev: ^rtlsdr_dev, rtl_freq_hz: ^u32, tuner_freq_hz: ^u32) -> i32 ---
    rtlsdr_get_usb_strings :: proc(dev: ^rtlsdr_dev, manufact: ^u8, product: ^u8, serial: ^u8) -> i32 ---
    rtlsdr_write_eeprom :: proc(dev: ^rtlsdr_dev, data: ^u8, offset: u8, length: u16) -> i32 ---
    rtlsdr_read_eeprom  :: proc(dev: ^rtlsdr_dev, data: ^u8, offset: u8, length: u16) -> i32 ---

    // // ---------- Frequency / rate / correction ----------
    rtlsdr_set_center_freq :: proc(dev: ^rtlsdr_dev, freq_hz: u32) -> i32 ---
    rtlsdr_get_center_freq :: proc(dev: ^rtlsdr_dev) -> u32 ---
    rtlsdr_set_freq_correction :: proc(dev: ^rtlsdr_dev, ppm: i32) -> i32 ---
    rtlsdr_get_freq_correction :: proc(dev: ^rtlsdr_dev) -> i32 ---
    rtlsdr_set_sample_rate :: proc(dev: ^rtlsdr_dev, rate_hz: u32) -> i32 ---
    rtlsdr_get_sample_rate :: proc(dev: ^rtlsdr_dev) -> u32 ---

    // // ---------- Gain / tuner ----------
    // // Note: gains array retrieval - pass nil to get count (-1 on error)
    rtlsdr_get_tuner_gains :: proc(dev: ^rtlsdr_dev, gains: ^i32) -> i32 ---
    rtlsdr_set_tuner_gain_mode :: proc(dev: ^rtlsdr_dev, manual: i32) -> i32 ---
    rtlsdr_set_tuner_gain :: proc(dev: ^rtlsdr_dev, gain_tenth_db: i32) -> i32 ---
    rtlsdr_get_tuner_gain :: proc(dev: ^rtlsdr_dev) -> i32 ---
    rtlsdr_set_tuner_if_gain :: proc(dev: ^rtlsdr_dev, stage: i32, gain_tenth_db: i32) -> i32 ---
    rtlsdr_set_agc_mode :: proc(dev: ^rtlsdr_dev, enabled: i32) -> i32 ---
    rtlsdr_get_tuner_type :: proc(dev: ^rtlsdr_dev) -> i32 --- // maps to enum below

    // // ---------- Direct sampling + offset tuning ----------
    rtlsdr_set_direct_sampling :: proc(dev: ^rtlsdr_dev, on: i32) -> i32 ---
    rtlsdr_get_direct_sampling :: proc(dev: ^rtlsdr_dev) -> i32 ---
    rtlsdr_set_offset_tuning :: proc(dev: ^rtlsdr_dev, on: i32) -> i32 ---
    rtlsdr_get_offset_tuning :: proc(dev: ^rtlsdr_dev) -> i32 ---

    // // ---------- IQ correction ----------
    rtlsdr_set_iq_balance :: proc(dev: ^rtlsdr_dev, i: i16, q: i16) -> i32 ---

    // // ---------- Buffer / streaming (synchronous) ----------
    rtlsdr_reset_buffer :: proc(dev: ^rtlsdr_dev) -> i32 ---
    rtlsdr_read_sync    :: proc(dev: ^rtlsdr_dev, buf: rawptr, len: i32, n_read: ^i32) -> i32 ---

    // // ---------- Asynchronous streaming ----------
    // // Callback type: provided here as a nested declaration for convenience.
    rtlsdr_read_async :: proc(dev: ^rtlsdr_dev, cb: rtlsdr_read_async_cb_t, ctx: rawptr, num_buffers: u32, buf_len: u32) -> i32 ---
    rtlsdr_wait_async :: proc(dev: ^rtlsdr_dev, cb: rtlsdr_read_async_cb_t, ctx: rawptr) -> i32 ---
    rtlsdr_cancel_async :: proc(dev: ^rtlsdr_dev) -> i32 ---
}

