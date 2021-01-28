Time::DATE_FORMATS[:stepped_cache_key] = lambda { |time|
  time
    .change(sec: (time.sec.div(5) * 5))
    .utc.to_s(:usec)
}
