# Date filtering shared by the gallery's albums and its videos, so both
# answer the same query string: ?year=2026, ?month=2026-09, or a custom
# ?from=2026-01-01&to=2026-03-31 range.
#
# The three are checked most-specific first — a month wins over a year, and a
# year wins over a range — so a stale parameter left in the URL can never
# silently widen a narrower filter.
module App::EventDateFilter
  MONTH_PARAM = /\A(\d{4})-(\d{1,2})\z/

  def filter_by_event_date(ds, column = :event_date)
    if (m = qs[:month].to_s.strip.match(MONTH_PARAM))
      year, month = m[1].to_i, m[2].to_i
      return ds if month < 1 || month > 12

      start = Date.new(year, month, 1)
      return ds.where(column => start..(start.next_month - 1))
    end

    if qs[:year].present? && (year = qs[:year].to_i) > 0
      return ds.where(column => Date.new(year, 1, 1)..Date.new(year, 12, 31))
    end

    from = parse_event_date(qs[:from])
    to   = parse_event_date(qs[:to])
    ds = ds.where(Sequel[column] >= from) if from
    ds = ds.where(Sequel[column] <= to)   if to
    ds
  end

  # The years that actually have content, newest first — what the year
  # dropdown offers.
  def event_years(ds, column = :event_date)
    ds.exclude(column => nil)
      .select_map(Sequel.function(:extract, Sequel.lit("YEAR FROM #{column}")).cast(:integer))
      .compact
      .uniq
      .sort
      .reverse
  end

  private

  def parse_event_date(value)
    return nil if value.to_s.strip.empty?

    Date.parse(value.to_s)
  rescue Date::Error, ArgumentError
    nil
  end
end
