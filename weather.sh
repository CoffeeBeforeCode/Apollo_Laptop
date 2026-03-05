#!/bin/bash

LAT="51.2840"
LON="-1.0893"

URL="https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&current=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_direction_10m,cloud_cover&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&wind_speed_unit=mph&timezone=Europe%2FLondon&forecast_days=1"

JSON=$(curl -s --max-time 10 "$URL")

if [ -z "$JSON" ]; then
    echo "Weather unavailable"
    exit 1
fi

python3 - << EOF
import json, sys

WMO_CODES = {
    0:"Clear sky",1:"Mainly clear",2:"Partly cloudy",3:"Overcast",
    45:"Foggy",48:"Depositing rime fog",51:"Light drizzle",53:"Drizzle",
    55:"Heavy drizzle",61:"Light rain",63:"Rain",65:"Heavy rain",
    66:"Light freezing rain",67:"Heavy freezing rain",71:"Light snow",
    73:"Snow",75:"Heavy snow",77:"Snow grains",80:"Light showers",
    81:"Showers",82:"Heavy showers",85:"Light snow showers",
    86:"Heavy snow showers",95:"Thunderstorm",96:"Thunderstorm w/ hail",
    99:"Thunderstorm w/ heavy hail",
}

def compass(d):
    return ["N","NE","E","SE","S","SW","W","NW"][round(d/45)%8]

data = json.loads("""${JSON}""")
cur  = data["current"]
day  = data["daily"]

print(WMO_CODES.get(cur["weather_code"], "Unknown"))
print(f'{round(cur["temperature_2m"])}C  (feels {round(cur["apparent_temperature"])}C)')
print(f'Hi {round(day["temperature_2m_max"][0])}C  /  Lo {round(day["temperature_2m_min"][0])}C')
print(f'Humidity  {cur["relative_humidity_2m"]}%')
print(f'Wind      {round(cur["wind_speed_10m"])} mph {compass(cur["wind_direction_10m"])}')
print(f'Cloud     {cur["cloud_cover"]}%')
print(f'Rain      {day["precipitation_sum"][0]} mm today')
EOF
