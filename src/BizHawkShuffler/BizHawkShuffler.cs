using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using BizHawk.Client.Common;
using BizHawk.Client.EmuHawk;

namespace BizhawkShuffler
{

    [ExternalTool("BizhawkShuffler")]
    public partial class BizhawkShuffler : ToolFormBase, IExternalToolForm
    {
        protected override string WindowTitleStatic => "Bizhawk Shuffler Setup";

        [RequiredApi]
        public IGameInfoApi GameInfo { get; set; } = default!;
        public ApiContainer APIs { get; set; } = default!;

        public BizhawkShuffler()
        {
            // needed for designer-generated controls
            InitializeComponent();
        }

        public override void Restart()
        {
        }

        protected override void UpdateAfter()
        {
        }
    }
}
