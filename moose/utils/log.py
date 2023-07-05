import logging

# set up logging to file
class CustomFormatter(logging.Formatter):
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"
    black = "\u001b[30m"
    green = "\u001b[32m"
    blue = "\u001b[34m"
    magenta = "\u001b[35m"
    cyan = "\u001b[36m"
    white = "\u001b[37m"
    lightpurple = "\x1b[38;5;69m" #[38;5;141m" #"\x1b[38;5;84m"
    pink90 = "\x1b[38;5;162m" #"\x1b[38;5;214m"
    
    def __init__(self, fmt,datefmt="%Y-%m-%d %H:%M:%S"):
        super().__init__()
        self.fmt = fmt
        self.datefmt = datefmt
        self.FORMATS = {
            logging.DEBUG: self.yellow + self.fmt + self.reset,
            logging.INFO: self.lightpurple + self.fmt + self.reset,
            logging.WARNING: self.pink90 + self.fmt + self.reset,
            logging.ERROR: self.red + self.fmt + self.reset,
            logging.CRITICAL: self.bold_red + self.fmt + self.reset
        }
    
    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)                
        formatter = logging.Formatter(log_fmt,self.datefmt)
        return formatter.format(record)
    


# set up logging to console
console = logging.StreamHandler()
console.setLevel(logging.DEBUG)
# set a format which is simpler for console use
format = "[%(asctime)s] [%(levelname)s] MOOSE | %(message)s"
console.setFormatter(CustomFormatter(format))

logger = logging.getLogger('MOOSE')
logger.setLevel(logging.INFO)
logger.addHandler(console)

def set_logger_level(ctx, self, value):
    logger.setLevel(logging.DEBUG)
    for handler in logger.handlers:
        handler.setLevel(logging.DEBUG)    
