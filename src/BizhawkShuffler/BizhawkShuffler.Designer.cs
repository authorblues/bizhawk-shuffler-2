
namespace BizhawkShuffler
{
    partial class BizhawkShuffler
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.tableLayoutPanelMain = new System.Windows.Forms.TableLayoutPanel();
            this.tabControlSetup = new System.Windows.Forms.TabControl();
            this.tabMain = new System.Windows.Forms.TabPage();
            this.tabPlugin = new System.Windows.Forms.TabPage();
            this.buttonStart = new System.Windows.Forms.Button();
            this.labelEnabledPlugins = new System.Windows.Forms.Label();
            this.tableLayoutPanelPlugin = new System.Windows.Forms.TableLayoutPanel();
            this.comboSelected = new System.Windows.Forms.ComboBox();
            this.checkPluginEnabled = new System.Windows.Forms.CheckBox();
            this.textBox1 = new System.Windows.Forms.TextBox();
            this.tableLayoutPanelMain.SuspendLayout();
            this.tabControlSetup.SuspendLayout();
            this.tabPlugin.SuspendLayout();
            this.tableLayoutPanelPlugin.SuspendLayout();
            this.SuspendLayout();
            // 
            // tableLayoutPanelMain
            // 
            this.tableLayoutPanelMain.ColumnCount = 2;
            this.tableLayoutPanelMain.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tableLayoutPanelMain.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 150F));
            this.tableLayoutPanelMain.Controls.Add(this.tabControlSetup, 0, 0);
            this.tableLayoutPanelMain.Controls.Add(this.buttonStart, 1, 1);
            this.tableLayoutPanelMain.Controls.Add(this.labelEnabledPlugins, 0, 1);
            this.tableLayoutPanelMain.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanelMain.Location = new System.Drawing.Point(0, 0);
            this.tableLayoutPanelMain.Name = "tableLayoutPanelMain";
            this.tableLayoutPanelMain.Padding = new System.Windows.Forms.Padding(10);
            this.tableLayoutPanelMain.RowCount = 2;
            this.tableLayoutPanelMain.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tableLayoutPanelMain.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 30F));
            this.tableLayoutPanelMain.Size = new System.Drawing.Size(734, 611);
            this.tableLayoutPanelMain.TabIndex = 0;
            // 
            // tabControlSetup
            // 
            this.tableLayoutPanelMain.SetColumnSpan(this.tabControlSetup, 2);
            this.tabControlSetup.Controls.Add(this.tabMain);
            this.tabControlSetup.Controls.Add(this.tabPlugin);
            this.tabControlSetup.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControlSetup.Location = new System.Drawing.Point(13, 13);
            this.tabControlSetup.Name = "tabControlSetup";
            this.tabControlSetup.Padding = new System.Drawing.Point(10, 5);
            this.tabControlSetup.SelectedIndex = 0;
            this.tabControlSetup.Size = new System.Drawing.Size(708, 555);
            this.tabControlSetup.TabIndex = 0;
            // 
            // tabMain
            // 
            this.tabMain.Location = new System.Drawing.Point(4, 26);
            this.tabMain.Name = "tabMain";
            this.tabMain.Padding = new System.Windows.Forms.Padding(15);
            this.tabMain.Size = new System.Drawing.Size(700, 525);
            this.tabMain.TabIndex = 0;
            this.tabMain.Text = "Shuffler Setup";
            this.tabMain.UseVisualStyleBackColor = true;
            // 
            // tabPlugin
            // 
            this.tabPlugin.Controls.Add(this.tableLayoutPanelPlugin);
            this.tabPlugin.Location = new System.Drawing.Point(4, 26);
            this.tabPlugin.Name = "tabPlugin";
            this.tabPlugin.Padding = new System.Windows.Forms.Padding(10);
            this.tabPlugin.Size = new System.Drawing.Size(700, 525);
            this.tabPlugin.TabIndex = 1;
            this.tabPlugin.Text = "Plugin Setup";
            this.tabPlugin.UseVisualStyleBackColor = true;
            // 
            // buttonStart
            // 
            this.buttonStart.AutoSize = true;
            this.buttonStart.Dock = System.Windows.Forms.DockStyle.Fill;
            this.buttonStart.Location = new System.Drawing.Point(577, 574);
            this.buttonStart.Name = "buttonStart";
            this.buttonStart.Size = new System.Drawing.Size(144, 24);
            this.buttonStart.TabIndex = 1;
            this.buttonStart.Text = "Begin Shuffler Session";
            this.buttonStart.UseVisualStyleBackColor = true;
            // 
            // labelEnabledPlugins
            // 
            this.labelEnabledPlugins.Anchor = System.Windows.Forms.AnchorStyles.Left;
            this.labelEnabledPlugins.AutoSize = true;
            this.labelEnabledPlugins.Location = new System.Drawing.Point(13, 579);
            this.labelEnabledPlugins.Name = "labelEnabledPlugins";
            this.labelEnabledPlugins.Size = new System.Drawing.Size(130, 13);
            this.labelEnabledPlugins.TabIndex = 2;
            this.labelEnabledPlugins.Text = "Enabled Plugins (0): None";
            this.labelEnabledPlugins.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // tableLayoutPanelPlugin
            // 
            this.tableLayoutPanelPlugin.ColumnCount = 3;
            this.tableLayoutPanelPlugin.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanelPlugin.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 6F));
            this.tableLayoutPanelPlugin.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 50F));
            this.tableLayoutPanelPlugin.Controls.Add(this.comboSelected, 0, 0);
            this.tableLayoutPanelPlugin.Controls.Add(this.checkPluginEnabled, 2, 0);
            this.tableLayoutPanelPlugin.Controls.Add(this.textBox1, 0, 1);
            this.tableLayoutPanelPlugin.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tableLayoutPanelPlugin.Location = new System.Drawing.Point(10, 10);
            this.tableLayoutPanelPlugin.Name = "tableLayoutPanelPlugin";
            this.tableLayoutPanelPlugin.RowCount = 2;
            this.tableLayoutPanelPlugin.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Absolute, 30F));
            this.tableLayoutPanelPlugin.RowStyles.Add(new System.Windows.Forms.RowStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.tableLayoutPanelPlugin.Size = new System.Drawing.Size(680, 505);
            this.tableLayoutPanelPlugin.TabIndex = 0;
            // 
            // comboSelected
            // 
            this.comboSelected.Dock = System.Windows.Forms.DockStyle.Fill;
            this.comboSelected.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.comboSelected.FormattingEnabled = true;
            this.comboSelected.Location = new System.Drawing.Point(3, 3);
            this.comboSelected.Name = "comboSelected";
            this.comboSelected.Size = new System.Drawing.Size(331, 21);
            this.comboSelected.TabIndex = 0;
            // 
            // checkPluginEnabled
            // 
            this.checkPluginEnabled.AutoSize = true;
            this.checkPluginEnabled.Dock = System.Windows.Forms.DockStyle.Fill;
            this.checkPluginEnabled.Location = new System.Drawing.Point(346, 3);
            this.checkPluginEnabled.Name = "checkPluginEnabled";
            this.checkPluginEnabled.Size = new System.Drawing.Size(331, 24);
            this.checkPluginEnabled.TabIndex = 1;
            this.checkPluginEnabled.Text = "Enabled";
            this.checkPluginEnabled.UseVisualStyleBackColor = true;
            // 
            // textBox1
            // 
            this.textBox1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.textBox1.Location = new System.Drawing.Point(3, 33);
            this.textBox1.Multiline = true;
            this.textBox1.Name = "textBox1";
            this.textBox1.ReadOnly = true;
            this.textBox1.Size = new System.Drawing.Size(331, 469);
            this.textBox1.TabIndex = 2;
            // 
            // BizhawkShuffler
            // 
            this.ClientSize = new System.Drawing.Size(734, 611);
            this.Controls.Add(this.tableLayoutPanelMain);
            this.Name = "BizhawkShuffler";
            this.tableLayoutPanelMain.ResumeLayout(false);
            this.tableLayoutPanelMain.PerformLayout();
            this.tabControlSetup.ResumeLayout(false);
            this.tabPlugin.ResumeLayout(false);
            this.tableLayoutPanelPlugin.ResumeLayout(false);
            this.tableLayoutPanelPlugin.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.TableLayoutPanel tableLayoutPanelMain;
        private System.Windows.Forms.TabControl tabControlSetup;
        private System.Windows.Forms.TabPage tabMain;
        private System.Windows.Forms.TabPage tabPlugin;
        private System.Windows.Forms.Button buttonStart;
        private System.Windows.Forms.Label labelEnabledPlugins;
        private System.Windows.Forms.TableLayoutPanel tableLayoutPanelPlugin;
        private System.Windows.Forms.ComboBox comboSelected;
        private System.Windows.Forms.CheckBox checkPluginEnabled;
        private System.Windows.Forms.TextBox textBox1;
    }
}