using System;
using System.Diagnostics;
using System.IO;
using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;

namespace BizHawkShuffler
{
    [ExternalTool("BizHawk Shuffler")]
    public partial class ShufflerTestForm : ToolFormBase, IExternalToolForm
    {
        // initialized by BizHawk through through reflection
        public ApiContainer ApiContainer { set => APIs.Update(value); }
        protected override string WindowTitleStatic => "BizHawk Shuffler";

        public Session? CurrentSession { get; private set; }



        public ShufflerTestForm()
        {
            InitializeComponent();
        }



        public override void Restart()
        {
            Trace.WriteLine("Restart");
            APIs.Update(MainForm);
        }

        protected override void UpdateAfter()
        {
            CurrentSession?.Update();
        }

        protected override void FastUpdateAfter()
        {
            CurrentSession?.Update();
        }

        public override bool AskSaveChanges()
        {
            Trace.WriteLine("AskSaveChanges");
            CurrentSession?.Save();
            return true;
        }



        private void NewSessionClicked(object sender, EventArgs e)
        {
            if (Directory.Exists(@"Shuffler\session 1\savestates"))
                Directory.Delete(@"Shuffler\session 1\savestates", recursive: true);
            CurrentSession = new Session(
                new System.IO.DirectoryInfo(@"Shuffler\session 1"),
                new SessionConfig
                {
                    TimedSwap = true,
                    MinSwapTime = TimeSpan.FromSeconds(5),
                    MaxSwapTime = TimeSpan.FromSeconds(15),
                    RandomOrder = true,
                }
            );
        }

        private void LoadSessionClicked(object sender, EventArgs e)
        {
            CurrentSession = Session.Load(new System.IO.DirectoryInfo(@"Shuffler\session 1"));
        }

        private void SaveSessionClicked(object sender, EventArgs e)
        {
            CurrentSession?.Save();
        }

        private void NextGameClicked(object sender, EventArgs e)
        {
            CurrentSession?.Swap();
        }

        private void MarkCompleteClicked(object sender, EventArgs e)
        {
            if (CurrentSession?.CurrentGame is not null)
            {
                CurrentSession.CurrentGame.Completed = true;
                CurrentSession.Swap();
            }
        }
    }
}
