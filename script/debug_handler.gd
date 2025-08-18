extends Node
class_name DebugHandler

var debug_mode := false

# File handler and path configuration
var log_file : File
var log_path = "user://logs/"

func _ready():
    _init_log_file()

# Initialize log file with timestamp
func _init_log_file():
    var dir = Directory.new()
    if !dir.dir_exists(log_path):
        dir.make_dir_recursive(log_path)
    
    # Generate filename using current datetime (YYYYMMDD_HHMMSS format)
    var datetime = OS.get_datetime()
    var filename = "log_%04d%02d%02d_%02d%02d%02d.txt" % [
        datetime.year, datetime.month, datetime.day,
        datetime.hour, datetime.minute, datetime.second
    ]
    
    log_file = File.new()
    if log_file.open(log_path + filename, File.WRITE) == OK:
        print("Log file created: ", filename)
    else:
        push_error("Failed to create log file")

# Write message with timestamp to log file
func write_log(log_type: String, message: String):
    if log_file.is_open():
        var time = OS.get_time()
        log_file.store_string("[%02d:%02d:%02d] [%s]: %s\n" % [
            time.hour, time.minute, time.second, log_type, message])
        log_file.flush()
