using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace BizHawkShuffler
{
    public class GameList : IReadOnlyList<Game>
    {
        private const string StateExtension = ".state";
        private static readonly HashSet<string> IgnoredExtensions = new(StringComparer.OrdinalIgnoreCase)
        {
            ".txt",
            ".bin",
            ".msu",
            ".pcm",
        };
        private static readonly StringComparer PathComparer = Environment.OSVersion.Platform == PlatformID.Win32NT ?
            StringComparer.OrdinalIgnoreCase : StringComparer.Ordinal;
        private static readonly StringComparison PathComparison = Environment.OSVersion.Platform == PlatformID.Win32NT ?
            StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal;



        private readonly List<Game> games;



        public Game this[int index] => games[index];
        public int Count => games.Count;
        public int CompletedCount => games.Count(game => game.Completed);
        public int UncompletedCount => games.Count(game => !game.Completed);



        public GameList()
        {
            games = new List<Game>();
        }

        public GameList(IEnumerable<Game> games)
        {
            this.games = new List<Game>(games);
        }



        public void Add(Game game)
        {
            game.StateName = GetStateName(game);
            games.Add(game);
        }

        private string GetStateName(Game game)
        {
            // Determine unique state file name instead of just using the rom file name to support games in multiple directories
            string baseName = Path.GetFileNameWithoutExtension(game.Path);
            string stateName = baseName + StateExtension;
            uint count = 1;
            while (games.Any(existingGame => PathComparer.Equals(existingGame.StateName, stateName)))
            {
                count++;
                stateName = baseName + "-" + count + StateExtension;
            }
            return stateName;
        }

        public void UpdateFrom(DirectoryInfo directory)
        {
            if (!directory.Exists)
                return;

            foreach (var file in directory.EnumerateFiles("*", SearchOption.AllDirectories))
            {
                if (IgnoredExtensions.Contains(file.Extension))
                    continue;

                var path = GetRelativePathIfNested(directory, file);

                // TODO: Handle cue files etc. 
                if (FindGame(path) is null)
                    Add(new Game(path));
            }

            // Mark all games that can't be found as completed so we don't try to swap to them anymore
            foreach (var game in games)
                if (!File.Exists(Path.Combine(directory.FullName, game.Path)))
                    game.Completed = true;
        }

        private Game? FindGame(string path)
        {
            return games.FirstOrDefault(game => PathComparer.Equals(path, game.Path));
        }



        /// <summary>
        /// Get path of <paramref name="file"/> relative to <paramref name="directory"/>.
        /// Returns absolute path if file is not inside directory.
        /// </summary>
        private static string GetRelativePathIfNested(DirectoryInfo directory, FileInfo file)
        {
            if (file.FullName.StartsWith(directory.FullName, PathComparison))
                return file.FullName.Substring(directory.FullName.Length).TrimStart('\\', '/');
            else
                return file.FullName;
        }



        public override string ToString() => $"{Count} games";

        IEnumerator<Game> IEnumerable<Game>.GetEnumerator() => games.GetEnumerator();
        IEnumerator IEnumerable.GetEnumerator() => games.GetEnumerator();

    }
}
