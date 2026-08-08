using System;
using System.Collections.Generic;

namespace localink_be.Models.DTOs
{
    public class BusinessHoursDto
    {
        public List<DayHoursDto> Days { get; set; } = new();
    }

    public class DayHoursDto
    {
        public string DayOfWeek { get; set; } = string.Empty;
        public string Mode { get; set; } = string.Empty;
        public List<TimeSlotDto> Slots { get; set; } = new();
    }

    public class TimeSlotDto
    {
        public TimeSpan OpenTime { get; set; }
        public TimeSpan CloseTime { get; set; }
    }
}
