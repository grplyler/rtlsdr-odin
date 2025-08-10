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