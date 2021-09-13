using System;

namespace BizHawkShuffler
{
    public class Game
    {
        public string Path { get; set; }
        public bool Completed { get; set; }
        public uint Swaps { get; set; }
        public TimeSpan Time { get; set; }
        public string? StateName { get; set; }

        public Game(string path)
        {
            Path = path;
        }

        public override string ToString() => Path + (Completed ? " [Complete]" : "");
    }
}
