class IcalGeneratorService
  def initialize(events:, device:)
    @events = events
    @device = device
  end

  def generate
    calendar = Icalendar::Calendar.new

    # Set calendar metadata
    calendar.x_wr_calname = calendar_name
    calendar.prodid = "-//LibreGig//Calendar//EN"
    calendar.version = "2.0"
    calendar.calscale = "GREGORIAN"

    # Add timezone component
    add_timezone(calendar)

    # Add events
    @events.each { |event| add_event(calendar, event) }

    calendar
  end

  private

  def calendar_name
    "LibreGig Calendar - #{@device.name}"
  end

  def add_timezone(calendar)
    # Use Rails configured timezone
    tz = Time.zone.tzinfo
    timezone = tz.identifier

    calendar.timezone do |t|
      t.tzid = timezone

      # Add standard time
      t.standard do |s|
        # Get the current offset in the format "+HH:MM" or "-HH:MM"
        offset = Time.zone.utc_offset
        hours = offset.abs / 3600
        minutes = (offset.abs % 3600) / 60
        formatted_offset = "%s%02d%02d" % [(offset >= 0) ? "+" : "-", hours, minutes]

        s.tzoffsetfrom = formatted_offset
        s.tzoffsetto = formatted_offset
        s.dtstart = "19700101T000000"
        s.tzname = tz.current_period.abbreviation
      end
    end
  end

  def add_event(calendar, event)
    calendar.event do |cal_event|
      cal_event.uid = "event-#{event.id}@libregig.com"
      cal_event.summary = event.name
      cal_event.description = event_description(event)

      if event.start_date
        cal_event.dtstart = Icalendar::Values::DateTime.new(event.start_date)
        cal_event.dtend = Icalendar::Values::DateTime.new(event.end_date || event.start_date)
      end

      cal_event.dtstamp = Icalendar::Values::DateTime.new(event.updated_at)
      cal_event.status = "CONFIRMED"
    end
  end

  def event_description(event)
    description = event.description.to_s

    if event.bands.any?
      band_names = event.bands.map(&:name).sort.join(", ")
      description += "\n\nBands: #{band_names}"
    end

    description
  end
end
