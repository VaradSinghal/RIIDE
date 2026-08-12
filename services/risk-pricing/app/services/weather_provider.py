"""
GigKavach — Risk & Pricing: Weather Provider Interface + Mock

Protocol-based interface so a real OpenWeather/AQICN/IMD client
can be swapped in without changing the service's public interface.
"""

import random
from typing import Protocol
from dataclasses import dataclass
from datetime import datetime


@dataclass
class WeatherData:
    temperature_c: float
    humidity_pct: float
    rainfall_6hr_mm: float
    wind_speed_kmh: float
    condition: str
    source: str
    timestamp: str


@dataclass
class AQIData:
    aqi: int
    category: str
    consecutive_hours: int
    pm25: float
    pm10: float
    source: str
    timestamp: str


@dataclass
class FloodAlert:
    active: bool
    message: str
    severity: str
    zone: str
    source: str


class WeatherProvider(Protocol):
    """Interface for weather data providers."""
    def get_weather(self, h3_index: str, city: str) -> WeatherData: ...
    def get_aqi(self, h3_index: str, city: str) -> AQIData: ...
    def get_flood_alerts(self, h3_index: str, city: str) -> FloodAlert: ...


import math

class MockWeatherProvider:
    """
    Returns realistic simulated data per city using diurnal cycles.
    Drop-in replaceable with OpenWeatherProvider.
    """

    def get_weather(self, h3_index: str, city: str) -> WeatherData:
        base_temp = {"Chennai": 33, "Delhi": 35, "Mumbai": 31}.get(city, 32)
        
        # Realistic diurnal curve: peaks at 2 PM (14:00), lowest at 4 AM (04:00)
        hour = datetime.now().hour
        # Shift hour so peak is at pi/2 (which is sin(pi/2) = 1)
        # 14:00 -> pi/2, 2:00 -> -pi/2
        time_rad = ((hour - 8) / 12) * math.pi
        temp_fluctuation = math.sin(time_rad) * 6  # +/- 6 degrees
        
        current_temp = base_temp + temp_fluctuation

        base_rain = random.uniform(0, 10)
        # Heavy rain usually in evening/night or specific seasons, add some variance
        if 16 <= hour <= 22 and random.random() > 0.8:
            base_rain += random.uniform(20, 50)
            
        return WeatherData(
            temperature_c=round(current_temp, 1),
            humidity_pct=round(random.uniform(55, 90), 1),
            rainfall_6hr_mm=round(base_rain, 1),
            wind_speed_kmh=round(random.uniform(5, 25), 1),
            condition="Heavy Rain" if base_rain > 20 else "Light Rain" if base_rain > 5 else "Clear",
            source="OpenWeather API (Mock)",
            timestamp=datetime.now().isoformat(),
        )

    def get_aqi(self, h3_index: str, city: str) -> AQIData:
        base_aqi = {"Chennai": 95, "Delhi": 250, "Mumbai": 110}.get(city, 100)
        aqi = int(base_aqi + random.uniform(-30, 50))
        categories = {400: "Hazardous", 300: "Very Unhealthy", 200: "Unhealthy", 100: "Moderate"}
        category = "Good"
        for threshold, label in sorted(categories.items(), reverse=True):
            if aqi > threshold:
                category = label
                break
        return AQIData(
            aqi=aqi,
            category=category,
            consecutive_hours=random.randint(0, 6) if aqi > 300 else 0,
            pm25=round(aqi * 0.4, 1),
            pm10=round(aqi * 0.6, 1),
            source="AQICN API (Mock)",
            timestamp=datetime.now().isoformat(),
        )

    def get_flood_alerts(self, h3_index: str, city: str) -> FloodAlert:
        return FloodAlert(
            active=False,
            message=f"Flood monitoring for {city}",
            severity="none",
            zone=h3_index,
            source="IMD Alert Feed (Mock)",
        )


# Singleton — swap for OpenWeatherProvider in production
weather_provider: WeatherProvider = MockWeatherProvider()
