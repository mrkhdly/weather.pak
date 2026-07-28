#!/bin/bash
# harvest-conditions.sh
# Queries wttr.in for diverse locations and prints every unique
# condition string it sees.  Run on your local Linux machine.
#
# Usage:  bash harvest-conditions.sh
# Output: results saved to harvest-YYYY-MM-DD_HHMMSS.txt in the
#         script's directory, plus live progress to stdout.

DELAY=1          # seconds between requests (be polite to wttr.in)
TIMEOUT=8        # request timeout per location

# Output file with timestamp
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTPUT_DIR="$SCRIPT_DIR/conditions"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/harvest-${TIMESTAMP}.txt"

urlencode() {
    local string="$1" length i c
    length=${#string}
    for (( i=0; i<length; i++ )); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            ' ') printf '+' ;;
            ,) printf '%%2C' ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

LOCATIONS=(
  # --- Arctic / sub-arctic ---
  "Utqiagvik,AK"
  "Longyearbyen,Norway"
  "Murmansk,Russia"
  "Yellowknife,Canada"
  "Reykjavik,Iceland"
  "Tromsø,Norway"
  "Nuuk,Greenland"
  "Alert,Canada"
  "Eureka,Canada"
  "Iqaluit,Canada"
  "Inuvik,Canada"
  "Kirkenes,Norway"
  "Torshavn,Faroe Islands"

  # --- Cold / continental ---
  "Norilsk,Russia"
  "Yakutsk,Russia"
  "Oymyakon,Russia"
  "Verkhoyansk,Russia"
  "Ulaanbaatar,Mongolia"
  "Winnipeg,Canada"
  "Minneapolis,MN"
  "Helsinki,Finland"
  "Oslo,Norway"
  "Stockholm,Sweden"
  "Moscow,Russia"
  "St. Petersburg,Russia"
  "Warsaw,Poland"
  "Minsk,Belarus"
  "Kyiv,Ukraine"
  "Bucharest,Romania"
  "Belgrade,Serbia"
  "Kopaonik,Serbia"
  "Irkutsk,Russia"
  "Omsk,Russia"
  "Vladivostok,Russia"
  "Novosibirsk,Russia"
  "Yekaterinburg,Russia"
  "Kazan,Russia"
  "Krasnoyarsk,Russia"
  "Magadan,Russia"
  "Petropavlovsk-Kamchatsky,Russia"
  "Yuzhno-Sakhalinsk,Russia"
  "Astrakhan,Russia"
  "Sochi,Russia"

  # --- Central Asia ---
  "Almaty,Kazakhstan"
  "Astana,Kazakhstan"
  "Tashkent,Uzbekistan"
  "Bishkek,Kyrgyzstan"
  "Dushanbe,Tajikistan"
  "Ashgabat,Turkmenistan"
  "Kabul,Afghanistan"
  "Islamabad,Pakistan"
  "Lahore,Pakistan"
  "Karachi,Pakistan"

  # --- Temperate / oceanic ---
  "London,UK"
  "Dublin,Ireland"
  "Edinburgh,Scotland"
  "Aberdeen,Scotland"
  "Amsterdam,Netherlands"
  "Brussels,Belgium"
  "Paris,France"
  "Zurich,Switzerland"
  "Vienna,Austria"
  "Prague,Czech Republic"
  "Budapest,Hungary"
  "Berlin,Germany"
  "Copenhagen,Denmark"
  "Lisbon,Portugal"
  "Madrid,Spain"
  "Barcelona,Spain"
  "Milan,Italy"
  "Rome,Italy"
  "Athens,Greece"
  "Istanbul,Turkey"
  "Tbilisi,Georgia"
  "Sarajevo,Bosnia"
  "Skopje,Macedonia"
  "Tallinn,Estonia"
  "Riga,Latvia"
  "Vilnius,Lithuania"
  "Sofia,Bulgaria"
  "Zagreb,Croatia"
  "Ljubljana,Slovenia"
  "Bratislava,Slovakia"
  "Valletta,Malta"
  "Nicosia,Cyprus"
  "Bergen,Norway"

  # --- Middle East / Caucasus ---
  "Riyadh,Saudi Arabia"
  "Dubai,UAE"
  "Abu Dhabi,UAE"
  "Kuwait City,Kuwait"
  "Muscat,Oman"
  "Doha,Qatar"
  "Manama,Bahrain"
  "Baghdad,Iraq"
  "Basra,Iraq"
  "Tehran,Iran"
  "Ahvaz,Iran"
  "Beirut,Lebanon"
  "Damascus,Syria"
  "Amman,Jordan"
  "Jerusalem,Israel"
  "Sanaa,Yemen"
  "Baku,Azerbaijan"
  "Yerevan,Armenia"

  # --- Arid / semi-arid / extreme heat ---
  "Phoenix,AZ"
  "Las Vegas,NV"
  "Death Valley,CA"
  "Tucson,AZ"
  "Palm Springs,CA"
  "Cairo,Egypt"
  "Marrakesh,Morocco"
  "Tunis,Tunisia"
  "Algiers,Algeria"
  "Windhoek,Namibia"
  "Lima,Peru"
  "Atacama,Chile"
  "Khartoum,Sudan"
  "Tripoli,Libya"
  "Dallol,Ethiopia"
  "Timbuktu,Mali"
  "Gaborone,Botswana"

  # --- Africa ---
  "Lagos,Nigeria"
  "Accra,Ghana"
  "Abidjan,Ivory Coast"
  "Nairobi,Kenya"
  "Dar es Salaam,Tanzania"
  "Addis Ababa,Ethiopia"
  "Dakar,Senegal"
  "Bamako,Mali"
  "Niamey,Niger"
  "Ndjamena,Chad"
  "Kinshasa,DR Congo"
  "Kampala,Uganda"
  "Lusaka,Zambia"
  "Harare,Zimbabwe"
  "Maputo,Mozambique"
  "Antananarivo,Madagascar"
  "Lilongwe,Malawi"
  "Luanda,Angola"
  "Libreville,Gabon"
  "Douala,Cameroon"
  "Mogadishu,Somalia"
  "Djibouti,Djibouti"
  "Asmara,Eritrea"
  "Juba,South Sudan"
  "Victoria Falls,Zimbabwe"
  "Cape Town,South Africa"
  "Johannesburg,South Africa"

  # --- Tropical / humid ---
  "Miami,FL"
  "Key West,FL"
  "Honolulu,HI"
  "Hilo,HI"
  "Havana,Cuba"
  "Cancun,Mexico"
  "Caracas,Venezuela"
  "Bogota,Colombia"
  "Quito,Ecuador"
  "Manaus,Brazil"
  "Belem,Brazil"
  "Rio de Janeiro,Brazil"
  "Sao Paulo,Brazil"
  "Brasilia,Brazil"
  "Fortaleza,Brazil"
  "Colombo,Sri Lanka"
  "Mumbai,India"
  "Chennai,India"
  "Yangon,Myanmar"
  "Bangkok,Thailand"
  "Singapore"
  "Kuala Lumpur,Malaysia"
  "Manila,Philippines"
  "Jakarta,Indonesia"
  "Darwin,Australia"
  "Male,Maldives"
  "Dili,Timor-Leste"
  "Bandar Seri Begawan,Brunei"

  # --- Caribbean & Central America ---
  "San Juan,Puerto Rico"
  "Santo Domingo,Dominican Republic"
  "Port-au-Prince,Haiti"
  "Kingston,Jamaica"
  "Bridgetown,Barbados"
  "Nassau,Bahamas"
  "Guatemala City,Guatemala"
  "San Salvador,El Salvador"
  "Tegucigalpa,Honduras"
  "Managua,Nicaragua"
  "San Jose,Costa Rica"
  "Panama City,Panama"
  "Port of Spain,Trinidad and Tobago"
  "Aruba"

  # --- Monsoonal / variable ---
  "Delhi,India"
  "Kolkata,India"
  "Mawsynram,India"
  "Cherrapunji,India"
  "Dhaka,Bangladesh"
  "Kathmandu,Nepal"
  "Thimphu,Bhutan"
  "Chengdu,China"
  "Hong Kong"
  "Taipei,Taiwan"
  "Tokyo,Japan"
  "Seoul,South Korea"
  "Busan,South Korea"
  "Osaka,Japan"
  "Sapporo,Japan"
  "Okinawa,Japan"
  "Fukuoka,Japan"
  "Hanoi,Vietnam"
  "Ho Chi Minh City,Vietnam"
  "Phnom Penh,Cambodia"
  "Vientiane,Laos"

  # --- More China ---
  "Beijing,China"
  "Shanghai,China"
  "Guangzhou,China"
  "Urumqi,China"
  "Lhasa,China"
  "Harbin,China"
  "Kunming,China"
  "Wuhan,China"
  "Pyongyang,North Korea"

  # --- Temperate Southern Hemisphere ---
  "Sydney,Australia"
  "Melbourne,Australia"
  "Auckland,New Zealand"
  "Wellington,New Zealand"
  "Buenos Aires,Argentina"
  "Santiago,Chile"
  "Ushuaia,Argentina"
  "Punta Arenas,Chile"
  "Perth,Australia"
  "Brisbane,Australia"
  "Hobart,Australia"
  "Montevideo,Uruguay"
  "Asuncion,Paraguay"
  "La Paz,Bolivia"
  "Cusco,Peru"
  "Galapagos Islands,Ecuador"
  "Valparaiso,Chile"

  # --- Pacific Islands ---
  "Suva,Fiji"
  "Nadi,Fiji"
  "Apia,Samoa"
  "Nuku'alofa,Tonga"
  "Port Moresby,Papua New Guinea"
  "Honiara,Solomon Islands"
  "Port Vila,Vanuatu"
  "Papeete,French Polynesia"
  "Guam"
  "Majuro,Marshall Islands"
  "Tarawa,Kiribati"
  "Funafuti,Tuvalu"
  "Noumea,New Caledonia"
  "Norfolk Island"

  # --- North America variety ---
  "Anchorage,AK"
  "Fairbanks,AK"
  "Nome,AK"
  "Seattle,WA"
  "Portland,OR"
  "San Francisco,CA"
  "Los Angeles,CA"
  "San Diego,CA"
  "Salt Lake City,UT"
  "Denver,CO"
  "Albuquerque,NM"
  "Dallas,TX"
  "Houston,TX"
  "New Orleans,LA"
  "Memphis,TN"
  "Nashville,TN"
  "Atlanta,GA"
  "Charlotte,NC"
  "Washington,DC"
  "Philadelphia,PA"
  "New York,NY"
  "Boston,MA"
  "Chicago,IL"
  "Detroit,MI"
  "Kansas City,MO"
  "Omaha,NE"
  "Bismarck,ND"
  "Mount Washington,NH"
  "San Antonio,TX"
  "Crater Lake,OR"

  # --- More Canada ---
  "Toronto,Canada"
  "Vancouver,Canada"
  "Calgary,Canada"
  "Edmonton,Canada"
  "Quebec City,Canada"
  "Halifax,Canada"
  "St. John's,Canada"
  "Whitehorse,Canada"

  # --- Mexico ---
  "Mexico City,Mexico"
  "Guadalajara,Mexico"
  "Monterrey,Mexico"
  "Merida,Mexico"
  "Tijuana,Mexico"

  # --- Atlantic / remote islands ---
  "Las Palmas,Spain"
  "Tenerife,Spain"
  "Ponta Delgada,Portugal"
  "Funchal,Portugal"
  "Bermuda"
  "Saint Helena"
  "Praia,Cape Verde"
  "Port Louis,Mauritius"
  "Saint-Denis,Reunion"
  "Socotra,Yemen"

  # --- More Africa ---
  "Abuja,Nigeria"
  "Yaounde,Cameroon"
  "Ouagadougou,Burkina Faso"
  "Conakry,Guinea"
  "Monrovia,Liberia"
  "Kigali,Rwanda"
  "Bujumbura,Burundi"
  "Lome,Togo"
  "Nouakchott,Mauritania"
  "Bangui,Central African Republic"
  "Brazzaville,Congo"
  "Victoria,Seychelles"
  "Maseru,Lesotho"

  # --- More South America ---
  "Medellin,Colombia"
  "Guayaquil,Ecuador"
  "Santa Cruz,Bolivia"
  "Cordoba,Argentina"
  "Salvador,Brazil"
  "Recife,Brazil"
  "Cayenne,French Guiana"
  "Paramaribo,Suriname"
  "Georgetown,Guyana"

  # --- More Europe & Mediterranean ---
  "Podgorica,Montenegro"
  "Chisinau,Moldova"
  "Luxembourg,Luxembourg"
  "Andorra la Vella,Andorra"
  "Porto,Portugal"
  "Palermo,Italy"
  "Heraklion,Greece"

  # --- More Asia ---
  "Bangalore,India"
  "Hyderabad,India"
  "Jaipur,India"
  "Chongqing,China"
  "Shenzhen,China"
  "Xi'an,China"
  "Nagoya,Japan"
  "Denpasar,Indonesia"
  "Cebu,Philippines"
  "Da Nang,Vietnam"

  # --- More Caribbean ---
  "Montego Bay,Jamaica"
  "Castries,Saint Lucia"
  "Basseterre,Saint Kitts"

  # --- More Oceania ---
  "Christchurch,New Zealand"
  "Palikir,Micronesia"

  # --- More European Capitals ---
  "Tirana,Albania"
  "Bern,Switzerland"
  "Vaduz,Liechtenstein"
  "Monaco,Monaco"
  "San Marino,San Marino"
  "Pristina,Kosovo"

  # --- More North American Capitals ---
  "Ottawa,Canada"
  "Belmopan,Belize"
  "St. John's,Antigua and Barbuda"
  "Roseau,Dominica"
  "St. George's,Grenada"
  "Kingstown,Saint Vincent"

  # --- More Asian Capitals ---
  "Ankara,Turkey"
  "Naypyidaw,Myanmar"

  # --- More African Capitals ---
  "Banjul,Gambia"
  "Bissau,Guinea-Bissau"
  "Dodoma,Tanzania"
  "Freetown,Sierra Leone"
  "Malabo,Equatorial Guinea"
  "Mbabane,Eswatini"
  "Moroni,Comoros"
  "Porto-Novo,Benin"
  "Pretoria,South Africa"
  "Rabat,Morocco"
  "Sao Tome,Sao Tome and Principe"

  # --- More Oceanian Capitals ---
  "Canberra,Australia"
  "Yaren,Nauru"
  "Ngerulmud,Palau"
)

SEEN_FILE=$(mktemp)
ERROR_FILE=$(mktemp)
trap 'rm -f "$SEEN_FILE" "$ERROR_FILE"' EXIT

TOTAL=${#LOCATIONS[@]}
START_TIME=$(date +%s)

echo "Querying $TOTAL locations…"
echo "Output: $OUTPUT_FILE"
echo ""

for i in "${!LOCATIONS[@]}"; do
    loc="${LOCATIONS[$i]}"
    count=$((i + 1))

    # Elapsed time
    elapsed=$(( $(date +%s) - START_TIME ))
    elapsed_min=$((elapsed / 60))
    elapsed_sec=$((elapsed % 60))

    loc_enc=$(urlencode "$loc")

    raw=$(curl -s --max-time "$TIMEOUT" "http://wttr.in/${loc_enc}?format=%C" 2>/dev/null)
    status=$?

    if [ $status -ne 0 ] || [ -z "$raw" ]; then
        printf "  [%3d/%d] %02d:%02d  ERR  %s\n" "$count" "$TOTAL" "$elapsed_min" "$elapsed_sec" "$loc" >&2
        echo "$loc" >> "$ERROR_FILE"
    else
        # Strip leading/trailing whitespace
        condition="${raw#"${raw%%[![:space:]]*}"}"
        condition="${condition%"${condition##*[![:space:]]}"}"
        printf "  [%3d/%d] %02d:%02d  OK   %s → %s\n" "$count" "$TOTAL" "$elapsed_min" "$elapsed_sec" "$loc" "$condition"
        echo "$condition | $loc" >> "$SEEN_FILE"
    fi

    sleep "$DELAY"
done

# Write results to output file
{
    echo "# Harvested: $(date)"
    echo "# Locations queried: $TOTAL"
    echo "# Failed queries: $([ -s "$ERROR_FILE" ] && wc -l < "$ERROR_FILE" || echo 0)"
    echo "#"
    echo "# Each line: condition | location"
    echo "#"
    sort -u "$SEEN_FILE"
    echo "# ---"
    echo "# Unique condition strings: $(cut -d'|' -f1 "$SEEN_FILE" | sort -u | wc -l)"
    echo "# Condition-location pairs: $(wc -l < "$SEEN_FILE")"

    if [ -s "$ERROR_FILE" ]; then
        echo "#"
        echo "# Failed locations ($(wc -l < "$ERROR_FILE") total):"
        while IFS= read -r loc; do
            echo "#   $loc"
        done < "$ERROR_FILE"
    fi
} > "$OUTPUT_FILE"

# Also print summary to stdout
echo ""
echo "Results saved to: $OUTPUT_FILE"
echo "Unique condition strings: $(cut -d'|' -f1 "$SEEN_FILE" | sort -u | wc -l)"
echo "Failed queries: $([ -s "$ERROR_FILE" ] && wc -l < "$ERROR_FILE" || echo 0)"