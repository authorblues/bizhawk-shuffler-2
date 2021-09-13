using System;

namespace BizHawkShuffler
{
    public class SessionConfig
    {

        public bool TimedSwap { get; set; }
        public TimeSpan MinSwapTime { get; set; }
        public TimeSpan MaxSwapTime { get; set; }

        public bool RandomOrder { get; set; }

    }
}
