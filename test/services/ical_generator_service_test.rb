require "test_helper"

class IcalGeneratorServiceTest < ActiveSupport::TestCase
  context "generating iCal calendar" do
    setup do
      @user = create(:user)
      @device = create(:linked_device, user: @user, name: "My Test Device")
      @events = []

      # Create events with various configurations
      @event1 = create(:event,
        owner: @user,
        name: "Event with start and end",
        description: "Test description",
        start_date: DateTime.parse("2024-12-25 10:00:00"),
        end_date: DateTime.parse("2024-12-25 12:00:00"))
      @events << @event1

      @event2 = create(:event,
        owner: @user,
        name: "Event with only start",
        start_date: DateTime.parse("2024-12-26 14:00:00"),
        end_date: nil)
      @events << @event2

      @event3 = create(:event,
        owner: @user,
        name: "Event without dates",
        start_date: nil,
        end_date: nil)
      @events << @event3

      @service = IcalGeneratorService.new(events: @events, device: @device)
    end

    should "generate valid iCalendar format" do
      calendar = @service.generate
      ical_string = calendar.to_ical

      # Check calendar metadata
      assert ical_string.include?("BEGIN:VCALENDAR")
      assert ical_string.include?("VERSION:2.0")
      assert ical_string.include?("PRODID:-//LibreGig//Calendar//EN")
      assert ical_string.include?("CALSCALE:GREGORIAN")
      assert ical_string.include?("X-WR-CALNAME:LibreGig Calendar - My Test Device")
      assert ical_string.include?("END:VCALENDAR")

      # Check timezone component
      assert ical_string.include?("BEGIN:VTIMEZONE")
      assert ical_string.include?("END:VTIMEZONE")
    end

    should "include all events" do
      calendar = @service.generate
      ical_string = calendar.to_ical

      # Check all events are included
      assert ical_string.include?("SUMMARY:Event with start and end")
      assert ical_string.include?("SUMMARY:Event with only start")
      assert ical_string.include?("SUMMARY:Event without dates")
    end

    should "properly format event with dates" do
      calendar = @service.generate
      ical_string = calendar.to_ical

      assert ical_string.include?("UID:event-#{@event1.id}@libregig.com")
      assert ical_string.include?("DESCRIPTION:Test description")
      assert ical_string.include?("STATUS:CONFIRMED")

      # Should have both start and end times
      assert ical_string.match(/DTSTART.*20241225T\d{6}/)
      assert ical_string.match(/DTEND.*20241225T\d{6}/)
    end

    should "handle event with only start date" do
      calendar = @service.generate
      ical_string = calendar.to_ical

      # Find the event section
      event_section = ical_string.split("BEGIN:VEVENT").find { |s| s.include?("Event with only start") }

      # Should use start date for both start and end
      assert event_section.match(/DTSTART.*20241226T\d{6}/)
      assert event_section.match(/DTEND.*20241226T\d{6}/)
    end

    should "include band information in description" do
      # Add bands to an event
      band1 = create(:band, name: "Rock Band")
      band2 = create(:band, name: "Jazz Ensemble")
      @event1.bands << band1
      @event1.bands << band2

      service = IcalGeneratorService.new(events: [@event1], device: @device)
      calendar = service.generate
      ical_string = calendar.to_ical

      # Bands should be sorted alphabetically
      assert ical_string.include?("DESCRIPTION:Test description\\n\\nBands: Jazz Ensemble\\, Rock Band")
    end
  end

  context "timezone handling" do
    should "include Rails configured timezone" do
      # Temporarily set timezone
      original_tz = Time.zone
      Time.zone = "America/New_York"

      service = IcalGeneratorService.new(events: [], device: create(:linked_device))
      calendar = service.generate
      ical_string = calendar.to_ical

      assert ical_string.include?("TZID:America/New_York")

      # Restore original timezone
      Time.zone = original_tz
    end
  end
end
