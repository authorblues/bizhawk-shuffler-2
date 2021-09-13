using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Newtonsoft.Json;

namespace BizHawkShuffler
{
    public class Session
    {
        private const string StatesDirectoryName = "savestates";
        private const string GamesDirectoryName = "games";
        private const string SessionDirectoryPrefix = "session";
        private const string SessionConfigName = "session.json";



        private readonly Stopwatch stopwatch = new();
        private readonly Random random = new(); // TODO: Seed and serialize PRNG
        private readonly DirectoryInfo sessionDir;
        private readonly DirectoryInfo gamesDir;
        private readonly DirectoryInfo statesDir;
        [JsonProperty("CurrentGame")]
        private string? currentGameSerialized;



        [JsonRequired]
        public SessionConfig Config { get; set; }

        [JsonRequired]
        public GameList Games { get; private set; }

        [JsonIgnore]
        public Game? CurrentGame { get; private set; }

        public TimeSpan TimeSinceLastSwap { get; private set; }
        public TimeSpan NextSwapTime { get; private set; }
        public uint TotalSwaps { get; set; }
        public TimeSpan TotalTime { get; set; }

        public string Name => sessionDir.Name;



        private Session(DirectoryInfo directory)
        {
            // set by other constructor or deserialization
            Config = default!;
            Games = default!;
            sessionDir = directory;
            sessionDir.Create();
            gamesDir = directory.CreateSubdirectory(GamesDirectoryName);
            statesDir = directory.CreateSubdirectory(StatesDirectoryName);
        }

        public Session(DirectoryInfo directory, SessionConfig config)
            : this(directory)
        {
            Config = config;
            Games = new GameList();
            Games.UpdateFrom(gamesDir);
        }



        public void Update()
        {
            var elapsed = stopwatch.Elapsed;
            stopwatch.Restart();

            if (CurrentGame is not null && !CurrentGame.Completed && !APIs.Client.IsPaused())
            {
                TotalTime += elapsed;
                CurrentGame.Time += elapsed;
                TimeSinceLastSwap += elapsed;
            }

            if (TimeSinceLastSwap >= NextSwapTime)
                Swap();
        }

        private Game? GetNextGame()
        {
            Games.UpdateFrom(gamesDir);

            var candidateGames = Games.Where(game => !game.Completed && !game.Equals(CurrentGame)).ToList();
            if (candidateGames.Count == 0)
                return null;

            // TODO: Fixed-order swapping
            int nextIndex = random.Next(0, candidateGames.Count); // upper bound is exclusive
            Debug.WriteLine($"{nextIndex} / {candidateGames.Count - 1}");
            return candidateGames.ElementAtOrDefault(nextIndex); // get n-th uncompleted game
        }

        public bool Swap(Game? game = null)
        {
            UpdateNextSwapTime();

            game ??= GetNextGame();

            if (game is null)
                return false;

            TrySaveCurrentState();

            string path = Path.Combine(gamesDir.FullName, game.Path);

            try
            {
                Trace.WriteLine($"Load ROM: {path}");
                APIs.MainForm.StopSound();
                if (!APIs.LoadRom(path))
                    return false;
                Trace.WriteLine($"Loaded ROM: {APIs.MainForm.CurrentlyOpenRom}");
            }
            catch (Exception ex)
            {
                Trace.WriteLine("Failed to save state:");
                Trace.WriteLine(ex);
                return false;
            }
            finally
            {
                APIs.MainForm.StartSound();
            }

            CurrentGame = game;
            game.Swaps++;
            TotalSwaps++;
            TimeSinceLastSwap = TimeSpan.Zero;
            TryLoadCurrentState();
            return true;
        }

        private string GetStatePath(Game game)
        {
            if (!Games.Contains(game))
                throw new ArgumentException($"Game {game} does not belong to this session.");
            if (game.StateName == null)
                throw new InvalidOperationException($"State name for {game} has not been initialized.");

            return Path.Combine(statesDir.FullName, game.StateName);
        }

        private bool TryLoadCurrentState()
        {
            if (CurrentGame is null)
                return false;

            var path = GetStatePath(CurrentGame);
            try
            {
                Trace.WriteLine($"Load state of {CurrentGame} ({APIs.GameInfo.GetRomName()}) from \"{path}\"");
                if (File.Exists(path))
                    APIs.SaveState.Load(path, suppressOSD: true);
                return true;
            }
            catch (Exception ex)
            {
                Trace.WriteLine("Failed to load state:");
                Trace.WriteLine(ex);
                return false;
            }
        }

        private bool TrySaveCurrentState()
        {
            if (CurrentGame is null)
                return false;

            try
            {
                statesDir.Create();
                var path = GetStatePath(CurrentGame);
                Trace.WriteLine($"Save state of {CurrentGame} ({APIs.GameInfo.GetRomName()}) to \"{path}\"");
                APIs.SaveState.Save(path, suppressOSD: true);
                return true;
            }
            catch (Exception ex)
            {
                Trace.WriteLine("Failed to save state:");
                Trace.WriteLine(ex);
                return false;
            }
        }

        private void UpdateNextSwapTime()
        {
            var range = Math.Abs(Config.MaxSwapTime.TotalSeconds - Config.MinSwapTime.TotalSeconds);
            NextSwapTime = Config.MinSwapTime + TimeSpan.FromSeconds(range * random.NextDouble());
            TimeSinceLastSwap = TimeSpan.Zero;
            Debug.WriteLine($"Next swap in {NextSwapTime}");
        }



        public static List<Session> GetSessions(DirectoryInfo directory)
        {
            var sessions = new List<Session>();

            foreach (var sessionDir in directory.GetDirectories("*", SearchOption.TopDirectoryOnly))
            {
                if (!File.Exists(Path.Combine(sessionDir.FullName, SessionConfigName)))
                    continue;

                try
                {
                    var session = Load(sessionDir);
                    sessions.Add(session);
                }
                catch (Exception ex)
                {
                    Trace.WriteLine($"Error while loading session \"{sessionDir.Name}\":");
                    Trace.WriteLine(ex.ToString());
                }
            }

            return sessions;
        }

        public static Session CreateNew(DirectoryInfo directory, SessionConfig config)
        {
            for (uint i = 1; i < uint.MaxValue; i++)
            {
                var dir = new DirectoryInfo(Path.Combine(directory.FullName, $"{SessionDirectoryPrefix}{i}"));
                if (!dir.Exists)
                {
                    dir.Create();
                    return new Session(dir, config);
                }
            }
            throw new IOException("No unused session folder. That seems implausible.");
        }

        /// <summary>Load session from directory.</summary>
        /// <param name="directory">Directory that contains <c>session.json</c></param>
        public static Session Load(DirectoryInfo directory)
        {
            var session = new Session(directory);
            using (var reader = new StreamReader(Path.Combine(directory.FullName, SessionConfigName)))
            {
                Serialization.GetSerializer().Populate(reader, session);
            }
            session.Games.UpdateFrom(session.gamesDir);
            return session;
        }

        /// <summary>Save to <c>session.json</c></summary>
        public void Save()
        {
            using (var writer = new StreamWriter(Path.Combine(sessionDir.FullName, SessionConfigName)))
            {
                Serialization.GetSerializer().Serialize(writer, this);
            }
        }



        [System.Runtime.Serialization.OnSerializing]
        private void OnSerializingMethod(System.Runtime.Serialization.StreamingContext context)
        {
            currentGameSerialized = CurrentGame?.Path;
        }

        [System.Runtime.Serialization.OnDeserialized]
        private void OnDeserializedMethod(System.Runtime.Serialization.StreamingContext context)
        {
            if (currentGameSerialized is not null)
                CurrentGame = Games.FirstOrDefault(game => game.Path == currentGameSerialized);
        }


        public override string ToString() => Name;
    }

}
