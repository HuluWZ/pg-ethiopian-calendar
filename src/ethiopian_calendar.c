/*
 * ethiopian_calendar.c
 * 
 * PostgreSQL extension for converting Gregorian timestamps to Ethiopian calendar dates.
 * 
 * Implementation based on formulas from:
 *   Nachum Dershowitz & Edward M. Reingold,
 *   "Calendrical Calculations", Cambridge University Press.
 * 
 * The Ethiopian calendar has:
 *   - 13 months: 12 months of 30 days each, plus a 13th month of 5 or 6 days
 *   - Year starts around September 11-12 in the Gregorian calendar
 *   - Uses a different epoch than the Gregorian calendar
 * 
 * Conversion approach:
 *   1. Convert Gregorian date to Julian Day Number (JDN)
 *   2. Convert JDN to Ethiopian calendar date
 */

#include "postgres.h"
#include "fmgr.h"
#include "utils/date.h"
#include "utils/timestamp.h"
#include "utils/builtins.h"

PG_MODULE_MAGIC;

/*
 * Ethiopian calendar epoch: August 29, 8 CE in Gregorian calendar
 * This corresponds to JDN 1724221
 */
#define ETHIOPIAN_EPOCH 1724221

/*
 * Convert Gregorian date to Julian Day Number
 * 
 * Algorithm from "Calendrical Calculations" by Dershowitz & Reingold
 * 
 * Parameters:
 *   year, month, day: Gregorian calendar components
 * 
 * Returns: Julian Day Number
 */
static int
gregorian_to_jdn(int year, int month, int day)
{
    int a, y, m, jdn;

    /* Adjust for month/year if month is January or February */
    a = (14 - month) / 12;
    y = year + 4800 - a;
    m = month + 12 * a - 3;

    /* Calculate Julian Day Number */
    jdn = day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045;

    return jdn;
}

/*
 * Convert Julian Day Number to Gregorian date
 * 
 * Algorithm from "Calendrical Calculations" by Dershowitz & Reingold
 * 
 * Parameters:
 *   jdn: Julian Day Number
 *   year, month, day: Output parameters for Gregorian date components
 */
static void
jdn_to_gregorian(int jdn, int *year, int *month, int *day)
{
    int a, b, c, d, e, m;

    a = jdn + 32044;
    b = (4 * a + 3) / 146097;
    c = a - (b * 146097) / 4;
    d = (4 * c + 3) / 1461;
    e = c - (1461 * d) / 4;
    m = (5 * e + 2) / 153;

    *day = e - (153 * m + 2) / 5 + 1;
    *month = m + 3 - 12 * (m / 10);
    *year = b * 100 + d - 4800 + (m / 10);
}

/*
 * Convert Julian Day Number to Ethiopian calendar date
 * 
 * Algorithm from "Calendrical Calculations" by Dershowitz & Reingold
 * Chapter 4: Ethiopian Calendar
 * 
 * The Ethiopian calendar has:
 *   - 12 months of 30 days each (months 1-12: Meskerem, Tikimt, Hidar, Tahsas, etc.)
 *   - 1 month of 5 or 6 days (month 13, Pagumē)
 *   - Leap years have 6 days in month 13, regular years have 5
 *   - Leap years occur every 4 years (years where year % 4 == 3)
 *   - Year 1 in Ethiopian calendar started on August 29, 8 CE (Gregorian)
 * 
 * Formula from Calendrical Calculations:
 *   era = floor((jdn - ETHIOPIAN_EPOCH) / 1461)
 *   year_of_era = floor(((jdn - ETHIOPIAN_EPOCH) mod 1461) / 365)
 *   day_of_year = ((jdn - ETHIOPIAN_EPOCH) mod 1461) mod 365
 *   
 *   If year_of_era == 4, then year_of_era = 3 and day_of_year = 365
 *   
 *   year = 4 * era + year_of_era + 1
 *   
 *   month = floor(day_of_year / 30) + 1  (if day_of_year < 360)
 *   day = (day_of_year mod 30) + 1
 *   
 *   If day_of_year >= 360, then month = 13 and day = day_of_year - 360 + 1
 * 
 * Parameters:
 *   jdn: Julian Day Number
 *   year, month, day: Output parameters for Ethiopian date components
 */
static void
jdn_to_ethiopian(int jdn, int *year, int *month, int *day)
{
    int era, year_of_era, day_of_year;
    int days_since_epoch;
    
    /* Calculate days since Ethiopian epoch */
    days_since_epoch = jdn - ETHIOPIAN_EPOCH;
    
    /* Calculate era (4-year cycles) */
    era = days_since_epoch / 1461;
    
    /* Calculate year within the era (0-3) */
    year_of_era = (days_since_epoch % 1461) / 365;
    
    /* Calculate day of year (0-365) */
    day_of_year = (days_since_epoch % 1461) % 365;
    
    /* Handle the 4th year of the era (leap year with 366 days) */
    if (year_of_era == 4)
    {
        year_of_era = 3;
        day_of_year = 365;
    }
    
    /* Calculate Ethiopian year */
    *year = 4 * era + year_of_era + 1;
    
    /* Calculate month and day */
    if (day_of_year < 360)
    {
        /* Months 1-12: each has 30 days */
        *month = day_of_year / 30 + 1;
        *day = (day_of_year % 30) + 1;
    }
    else
    {
        /* Month 13 (Pagumē): 5 or 6 days */
        int is_leap;
        int max_days;
        
        *month = 13;
        *day = day_of_year - 360 + 1;
        
        /* Validate: month 13 has 5 days in regular years, 6 in leap years */
        /* Leap years: year % 4 == 3 */
        is_leap = (*year % 4 == 3);
        max_days = is_leap ? 6 : 5;
        
        if (*day > max_days)
        {
            *day = max_days;
        }
    }
}

/*
 * Convert Ethiopian calendar date to Julian Day Number
 * 
 * Algorithm from "Calendrical Calculations" by Dershowitz & Reingold
 * Inverse of jdn_to_ethiopian
 * 
 * Formula:
 *   era = floor((year - 1) / 4)
 *   year_of_era = (year - 1) mod 4
 *   
 *   If month <= 12:
 *     day_of_year = (month - 1) * 30 + day - 1
 *   Else (month == 13):
 *     day_of_year = 360 + day - 1
 *   
 *   jdn = ETHIOPIAN_EPOCH + era * 1461 + year_of_era * 365 + day_of_year
 * 
 * Parameters:
 *   year, month, day: Ethiopian calendar components
 * 
 * Returns: Julian Day Number
 */
static int
ethiopian_to_jdn(int year, int month, int day)
{
    int era, year_of_era, day_of_year, jdn;
    
    /* Calculate era (4-year cycles) and year within era */
    era = (year - 1) / 4;
    year_of_era = (year - 1) % 4;
    
    /* Calculate day of year (0-based) */
    if (month <= 12)
    {
        /* Months 1-12: each has 30 days */
        day_of_year = (month - 1) * 30 + (day - 1);
    }
    else
    {
        /* Month 13 (Pagumē): days 360-365 (or 360-366 in leap years) */
        day_of_year = 360 + (day - 1);
    }
    
    /* Calculate Julian Day Number */
    jdn = ETHIOPIAN_EPOCH + era * 1461 + year_of_era * 365 + day_of_year;
    
    return jdn;
}

/*
 * Convert PostgreSQL DATE (DateADT) to Gregorian date components
 * DateADT is stored as days since 2000-01-01 (POSTGRES_EPOCH_JDATE = 2451545)
 * 
 * Parameters:
 *   date_val: PostgreSQL DATE value (DateADT)
 *   year, month, day: Output parameters for Gregorian date components
 */
static void
dateadt_to_gregorian(DateADT date_val, int *year, int *month, int *day)
{
    int jdn;
    
    /* Convert DateADT to Julian Day Number */
    /* DateADT is days since 2000-01-01, which is JDN 2451545 */
    jdn = date_val + POSTGRES_EPOCH_JDATE;
    
    /* Convert JDN to Gregorian date */
    jdn_to_gregorian(jdn, year, month, day);
}

/*
 * Convert Gregorian date components to PostgreSQL DATE (DateADT)
 * 
 * Parameters:
 *   year, month, day: Gregorian calendar components
 * 
 * Returns: PostgreSQL DATE value (DateADT)
 */
static DateADT
gregorian_to_dateadt(int year, int month, int day)
{
    int jdn;
    DateADT date_val;
    
    /* Convert Gregorian date to Julian Day Number */
    jdn = gregorian_to_jdn(year, month, day);
    
    /* Convert JDN to DateADT (days since 2000-01-01) */
    date_val = jdn - POSTGRES_EPOCH_JDATE;
    
    return date_val;
}

/*
 * PostgreSQL function: to_ethiopian_date(timestamp)
 * 
 * Converts a Gregorian timestamp to an Ethiopian calendar date as text.
 * Returns the Ethiopian date in format: "YYYY-MM-DD"
 * The time component is discarded; only the date is converted.
 * 
 * Returns: TEXT (Ethiopian calendar date as string in format YYYY-MM-DD)
 */
PG_FUNCTION_INFO_V1(to_ethiopian_date);

Datum
to_ethiopian_date(PG_FUNCTION_ARGS)
{
    Timestamp timestamp_val;
    DateADT date_val;
    int eth_year, eth_month, eth_day;
    int greg_year, greg_month, greg_day;
    int jdn;
    char result_text[32];
    text *result;
    
    /* Handle NULL input */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();
    
    /* Get the timestamp value */
    timestamp_val = PG_GETARG_TIMESTAMP(0);
    
    /* Extract date part (discard time) */
    date_val = DatumGetDateADT(DirectFunctionCall1(timestamp_date, TimestampGetDatum(timestamp_val)));
    
    /* Convert PostgreSQL DATE to Gregorian components */
    dateadt_to_gregorian(date_val, &greg_year, &greg_month, &greg_day);
    
    /* Convert Gregorian date to Julian Day Number */
    jdn = gregorian_to_jdn(greg_year, greg_month, greg_day);
    
    /* Convert JDN to Ethiopian calendar */
    jdn_to_ethiopian(jdn, &eth_year, &eth_month, &eth_day);
    
    /* Format as text: "YYYY-MM-DD" */
    snprintf(result_text, sizeof(result_text), "%04d-%02d-%02d", eth_year, eth_month, eth_day);
    
    result = cstring_to_text(result_text);
    PG_RETURN_TEXT_P(result);
}

/*
 * PostgreSQL function: to_ethiopian_datetime(timestamp)
 * 
 * Converts a Gregorian timestamp to an Ethiopian calendar TIMESTAMP WITH TIME ZONE.
 * The date is converted to Ethiopian calendar; the time-of-day remains the same.
 * 
 * Note: The function signature returns TIMESTAMP WITH TIME ZONE, but we
 * return a TIMESTAMP (without time zone) since we preserve the original time.
 * The conversion only affects the date portion.
 * 
 * Returns: TIMESTAMP with Ethiopian calendar date and original time
 */
PG_FUNCTION_INFO_V1(to_ethiopian_datetime);

Datum
to_ethiopian_datetime(PG_FUNCTION_ARGS)
{
    Timestamp timestamp_val;
    DateADT date_val;
    int eth_year, eth_month, eth_day;
    int greg_year, greg_month, greg_day;
    int jdn;
    DateADT eth_date;
    Timestamp result_timestamp;
    TimeOffset time_offset;
    
    /* Handle NULL input */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();
    
    /* Get the timestamp value */
    timestamp_val = PG_GETARG_TIMESTAMP(0);
    
    /* Extract date and time components */
    date_val = DatumGetDateADT(DirectFunctionCall1(timestamp_date, TimestampGetDatum(timestamp_val)));
    time_offset = timestamp_val - (date_val * USECS_PER_DAY);
    
    /* Convert PostgreSQL DATE to Gregorian components */
    dateadt_to_gregorian(date_val, &greg_year, &greg_month, &greg_day);
    
    /* Convert Gregorian date to Julian Day Number */
    jdn = gregorian_to_jdn(greg_year, greg_month, greg_day);
    
    /* Convert JDN to Ethiopian calendar */
    jdn_to_ethiopian(jdn, &eth_year, &eth_month, &eth_day);
    
    /* Convert Ethiopian date back to Gregorian DATE (for PostgreSQL storage) */
    jdn = ethiopian_to_jdn(eth_year, eth_month, eth_day);
    jdn_to_gregorian(jdn, &greg_year, &greg_month, &greg_day);
    eth_date = gregorian_to_dateadt(greg_year, greg_month, greg_day);
    
    /* Combine Ethiopian date with original time */
    result_timestamp = (eth_date * USECS_PER_DAY) + time_offset;
    
    PG_RETURN_TIMESTAMP(result_timestamp);
}

/*
 * PostgreSQL function: from_ethiopian_date(text)
 * 
 * Converts an Ethiopian calendar date string to a Gregorian timestamp.
 * The input should be in format "YYYY-MM-DD" (Ethiopian calendar).
 * 
 * Parameters:
 *   ethiopian_date: Ethiopian calendar date as text (format: YYYY-MM-DD)
 * 
 * Returns: TIMESTAMP (Gregorian calendar timestamp at midnight)
 */
PG_FUNCTION_INFO_V1(from_ethiopian_date);

Datum
from_ethiopian_date(PG_FUNCTION_ARGS)
{
    text *input_text;
    char *date_str;
    int eth_year, eth_month, eth_day;
    int jdn;
    int greg_year, greg_month, greg_day;
    DateADT date_val;
    Timestamp result_timestamp;
    
    /* Handle NULL input */
    if (PG_ARGISNULL(0))
        PG_RETURN_NULL();
    
    /* Get the input text */
    input_text = PG_GETARG_TEXT_P(0);
    date_str = text_to_cstring(input_text);
    
    /* Parse the Ethiopian date string (format: YYYY-MM-DD) */
    if (sscanf(date_str, "%d-%d-%d", &eth_year, &eth_month, &eth_day) != 3)
    {
        ereport(ERROR,
                (errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
                 errmsg("invalid Ethiopian date format: %s (expected YYYY-MM-DD)", date_str)));
    }
    
    /* Validate month and day */
    if (eth_month < 1 || eth_month > 13)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
                 errmsg("invalid Ethiopian month: %d (must be 1-13)", eth_month)));
    }
    
    if (eth_day < 1)
    {
        ereport(ERROR,
                (errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
                 errmsg("invalid Ethiopian day: %d (must be >= 1)", eth_day)));
    }
    
    /* Validate day based on month */
    if (eth_month <= 12)
    {
        if (eth_day > 30)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
                     errmsg("invalid Ethiopian day: %d (month %d has 30 days)", eth_day, eth_month)));
        }
    }
    else /* month == 13 */
    {
        int is_leap = (eth_year % 4 == 3);
        int max_days = is_leap ? 6 : 5;
        if (eth_day > max_days)
        {
            ereport(ERROR,
                    (errcode(ERRCODE_DATETIME_VALUE_OUT_OF_RANGE),
                     errmsg("invalid Ethiopian day: %d (month 13 has %d days in year %d)", 
                            eth_day, max_days, eth_year)));
        }
    }
    
    /* Convert Ethiopian date to Julian Day Number */
    jdn = ethiopian_to_jdn(eth_year, eth_month, eth_day);
    
    /* Convert JDN to Gregorian date */
    jdn_to_gregorian(jdn, &greg_year, &greg_month, &greg_day);
    
    /* Convert Gregorian date to PostgreSQL DATE */
    date_val = gregorian_to_dateadt(greg_year, greg_month, greg_day);
    
    /* Convert DATE to TIMESTAMP (at midnight) */
    result_timestamp = date_val * USECS_PER_DAY;
    
    PG_RETURN_TIMESTAMP(result_timestamp);
}

