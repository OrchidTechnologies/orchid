import logging
import logging.config
import os
from colorlog import ColoredFormatter

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "colored": {
            "()": "colorlog.ColoredFormatter",
            "format": "%(asctime)s-%(name)s (%(log_color)s%(levelname)s%(reset)s): %(message)s",
            "log_colors": {
                "DEBUG": "cyan",
                "INFO": "green",
                "WARNING": "yellow",
                "ERROR": "red",
                "CRITICAL": "red,bg_white",
            },
            "secondary_log_colors": {},
            "style": "%"
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "colored",
            "level": "INFO"
        }
    },
    "loggers": {
        "": {
            "handlers": ["console"],
            "level": "INFO",
        },
        "uvicorn": {
            "handlers": ["console"],
            "level": "INFO",
        },
        "inference": {
            "handlers": ["console"],
            "level": os.getenv("ORCHID_GENAI_INF_LOGLVL", "INFO"),
            "propagate": False
        }
    }
}

def configure_logging():
    logging.config.dictConfig(LOGGING_CONFIG)
    logger = logging.getLogger("inference")
    
    logger.info("Inference API logging initialized")
    
    if logger.level <= logging.DEBUG:
        logger.warning("Debug logging enabled - ensure this is not used in production")
        
    return logger
