# Roadmap & Future Releases

## Version 1.1.0 (Next Release)

### Date Component Extraction
- [ ] `ethiopian_year(timestamp)` → Extract Ethiopian year
- [ ] `ethiopian_month(timestamp)` → Extract Ethiopian month (1-13)
- [ ] `ethiopian_day(timestamp)` → Extract Ethiopian day (1-30 or 1-6)

### Month Names
- [ ] `ethiopian_month_name(timestamp)` → Returns month name (Meskerem, Tikimt, etc.)
- [ ] `ethiopian_month_name_amharic(timestamp)` → Returns month name in Amharic script

### Date Formatting
- [ ] `to_ethiopian_date(timestamp, format)` → Custom format support
  - `YYYY` - Year
  - `MM` - Month number
  - `DD` - Day
  - `Month` - Month name
  - `Day` - Day name

---

## Version 1.2.0

### Date Arithmetic
- [ ] `ethiopian_add_days(timestamp, days)` → Add days in Ethiopian calendar
- [ ] `ethiopian_add_months(timestamp, months)` → Add months
- [ ] `ethiopian_add_years(timestamp, years)` → Add years
- [ ] `ethiopian_diff_days(timestamp, timestamp)` → Difference in days

### Date Validation
- [ ] `is_valid_ethiopian_date(text)` → Validate Ethiopian date string
- [ ] `ethiopian_days_in_month(year, month)` → Days in a given month
- [ ] `is_ethiopian_leap_year(year)` → Check if Ethiopian leap year

---

## Version 1.3.0

### Ethiopian Time Support
- [ ] `to_ethiopian_time(timestamp)` → Convert to Ethiopian time (6-hour offset)
- [ ] `from_ethiopian_time(timestamp)` → Convert from Ethiopian time
- [ ] `current_ethiopian_time()` → Current time in Ethiopian format

### Day Names
- [ ] `ethiopian_day_name(timestamp)` → Day of week name
- [ ] `ethiopian_day_of_week(timestamp)` → Day of week number (1-7)

---

## Version 2.0.0

### Ethiopian Holidays
- [ ] `is_ethiopian_holiday(timestamp)` → Check if date is a holiday
- [ ] `ethiopian_holiday_name(timestamp)` → Get holiday name
- [ ] `next_ethiopian_holiday(timestamp)` → Next holiday after date

### Fiscal Year Support
- [ ] `ethiopian_fiscal_year(timestamp)` → Ethiopian fiscal year
- [ ] `ethiopian_fiscal_quarter(timestamp)` → Fiscal quarter (1-4)

### Aggregations
- [ ] `ethiopian_date_trunc(field, timestamp)` → Truncate to year/month/day
- [ ] `ethiopian_date_part(field, timestamp)` → Extract date part

---

## Version 2.1.0

### Range Functions
- [ ] `ethiopian_date_range(start, end)` → Generate date series
- [ ] `ethiopian_months_between(timestamp, timestamp)` → Months between dates

### Operators
- [ ] Custom operators for Ethiopian date comparison
- [ ] Index support for Ethiopian date operations

---

## Ideas (Backlog)

### Internationalization
- [ ] Amharic numeral support (፩, ፪, ፫, etc.)
- [ ] Tigrinya month names
- [ ] Oromo calendar support

### Integration
- [ ] JSON output format
- [ ] ISO 8601 style formatting
- [ ] COPY format support

### Performance
- [ ] Parallel-safe functions
- [ ] Optimized batch conversions
- [ ] Caching for repeated conversions

---

## Contributing

Want to help implement these features? 

1. Fork the repository
2. Create a feature branch
3. Implement the feature with tests
4. Submit a pull request

GitHub: https://github.com/HuluWZ/pg-ethiopian-calendar

