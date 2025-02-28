"""
Unit conversion tool implementation.
"""
import logging
from typing import Dict, Any, Union, Optional

logger = logging.getLogger(__name__)

# Conversion factors for different unit types
CONVERSIONS = {
    "length": {
        "m": 1.0,  # base unit (meters)
        "km": 1000.0,
        "cm": 0.01,
        "mm": 0.001,
        "in": 0.0254,
        "ft": 0.3048,
        "yd": 0.9144,
        "mi": 1609.34
    },
    "mass": {
        "kg": 1.0,  # base unit (kilograms)
        "g": 0.001,
        "mg": 0.000001,
        "lb": 0.453592,
        "oz": 0.0283495
    },
    "volume": {
        "l": 1.0,  # base unit (liters)
        "ml": 0.001,
        "gal": 3.78541,
        "qt": 0.946353,
        "pt": 0.473176,
        "cup": 0.236588,
        "floz": 0.0295735
    },
    "temperature": {
        # Special case, handled separately
        "c": "celsius",
        "f": "fahrenheit",
        "k": "kelvin"
    },
    "area": {
        "m2": 1.0,  # base unit (square meters)
        "km2": 1000000.0,
        "cm2": 0.0001,
        "mm2": 0.000001,
        "in2": 0.00064516,
        "ft2": 0.092903,
        "ac": 4046.86,
        "ha": 10000.0
    },
    "time": {
        "s": 1.0,  # base unit (seconds)
        "ms": 0.001,
        "min": 60.0,
        "h": 3600.0,
        "day": 86400.0,
        "week": 604800.0
    }
}

def convert_temperature(value: float, from_unit: str, to_unit: str) -> float:
    """Special handling for temperature conversions."""
    # Convert to Kelvin first (as the intermediate unit)
    if from_unit == "c":
        kelvin = value + 273.15
    elif from_unit == "f":
        kelvin = (value - 32) * 5/9 + 273.15
    else:  # already kelvin
        kelvin = value
        
    # Convert from Kelvin to the target unit
    if to_unit == "c":
        return kelvin - 273.15
    elif to_unit == "f":
        return (kelvin - 273.15) * 9/5 + 32
    else:  # to kelvin
        return kelvin

def convert_unit(value: float, from_unit: str, to_unit: str, unit_type: str) -> Optional[float]:
    """Convert a value from one unit to another within the same type."""
    from_unit = from_unit.lower()
    to_unit = to_unit.lower()
    
    # Handle temperature separately
    if unit_type == "temperature":
        return convert_temperature(value, from_unit, to_unit)
        
    # For other unit types
    if unit_type in CONVERSIONS and from_unit in CONVERSIONS[unit_type] and to_unit in CONVERSIONS[unit_type]:
        # Convert to the base unit first, then to the target unit
        base_value = value * CONVERSIONS[unit_type][from_unit]
        return base_value / CONVERSIONS[unit_type][to_unit]
    
    return None

def execute(args: Dict[str, Any], context: Dict[str, Any]) -> str:
    """
    Execute the unit conversion tool.
    
    Args:
        args: Dictionary with 'value', 'from_unit', 'to_unit', and 'unit_type' keys
        context: Execution context (not used for unit conversion)
        
    Returns:
        String representation of the converted value
    """
    # Extract arguments
    value = args.get('value')
    from_unit = args.get('from_unit')
    to_unit = args.get('to_unit')
    unit_type = args.get('unit_type')
    
    # Validate arguments
    if value is None or from_unit is None or to_unit is None or unit_type is None:
        return "Error: Missing required parameters (value, from_unit, to_unit, unit_type)"
    
    try:
        value = float(value)
    except ValueError:
        return "Error: Value must be a number"
    
    if unit_type not in CONVERSIONS:
        return f"Error: Unsupported unit type. Supported types: {', '.join(CONVERSIONS.keys())}"
    
    # Normalize unit names and check if they are supported
    from_unit = from_unit.lower()
    to_unit = to_unit.lower()
    
    unit_map = CONVERSIONS[unit_type]
    if from_unit not in unit_map:
        return f"Error: Unsupported from_unit. Supported units for {unit_type}: {', '.join(unit_map.keys())}"
    
    if to_unit not in unit_map:
        return f"Error: Unsupported to_unit. Supported units for {unit_type}: {', '.join(unit_map.keys())}"
    
    # Perform the conversion
    result = convert_unit(value, from_unit, to_unit, unit_type)
    if result is None:
        return "Error: Conversion failed"
    
    # Format the result (round to 6 decimal places if needed)
    if result == int(result):
        return str(int(result))
    else:
        return str(round(result, 6))

# Tool definition for configuration
TOOL_DEFINITION = {
    "name": "unit_converter",
    "description": "Convert values between different units of measurement. Supports length, mass, volume, temperature, area, and time conversions.",
    "parameters": {
        "type": "object",
        "properties": {
            "value": {
                "type": "number",
                "description": "The numeric value to convert"
            },
            "from_unit": {
                "type": "string",
                "description": "The source unit (e.g., 'm', 'kg', 'c')"
            },
            "to_unit": {
                "type": "string",
                "description": "The target unit (e.g., 'ft', 'lb', 'f')"
            },
            "unit_type": {
                "type": "string",
                "description": "The type of conversion to perform",
                "enum": ["length", "mass", "volume", "temperature", "area", "time"]
            }
        },
        "required": ["value", "from_unit", "to_unit", "unit_type"]
    }
}