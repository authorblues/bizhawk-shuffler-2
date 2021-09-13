
namespace BizHawkShuffler
{
    partial class ShufflerTestForm
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
            this.newSessionButton = new System.Windows.Forms.Button();
            this.loadSessionButton = new System.Windows.Forms.Button();
            this.saveSessionButton = new System.Windows.Forms.Button();
            this.nextGameButton = new System.Windows.Forms.Button();
            this.markCompleteButton = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // newSessionButton
            // 
            this.newSessionButton.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.newSessionButton.Location = new System.Drawing.Point(12, 12);
            this.newSessionButton.Name = "newSessionButton";
            this.newSessionButton.Size = new System.Drawing.Size(175, 25);
            this.newSessionButton.TabIndex = 0;
            this.newSessionButton.Text = "New Session";
            this.newSessionButton.UseVisualStyleBackColor = true;
            this.newSessionButton.Click += new System.EventHandler(this.NewSessionClicked);
            // 
            // loadSessionButton
            // 
            this.loadSessionButton.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.loadSessionButton.Location = new System.Drawing.Point(11, 43);
            this.loadSessionButton.Name = "loadSessionButton";
            this.loadSessionButton.Size = new System.Drawing.Size(176, 25);
            this.loadSessionButton.TabIndex = 1;
            this.loadSessionButton.Text = "Load Session";
            this.loadSessionButton.UseVisualStyleBackColor = true;
            this.loadSessionButton.Click += new System.EventHandler(this.LoadSessionClicked);
            // 
            // saveSessionButton
            // 
            this.saveSessionButton.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.saveSessionButton.Location = new System.Drawing.Point(12, 74);
            this.saveSessionButton.Name = "saveSessionButton";
            this.saveSessionButton.Size = new System.Drawing.Size(176, 25);
            this.saveSessionButton.TabIndex = 2;
            this.saveSessionButton.Text = "Save Session";
            this.saveSessionButton.UseVisualStyleBackColor = true;
            this.saveSessionButton.Click += new System.EventHandler(this.SaveSessionClicked);
            // 
            // nextGameButton
            // 
            this.nextGameButton.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.nextGameButton.Location = new System.Drawing.Point(12, 105);
            this.nextGameButton.Name = "nextGameButton";
            this.nextGameButton.Size = new System.Drawing.Size(176, 25);
            this.nextGameButton.TabIndex = 3;
            this.nextGameButton.Text = "Next Game";
            this.nextGameButton.UseVisualStyleBackColor = true;
            this.nextGameButton.Click += new System.EventHandler(this.NextGameClicked);
            // 
            // markCompleteButton
            // 
            this.markCompleteButton.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.markCompleteButton.Location = new System.Drawing.Point(12, 136);
            this.markCompleteButton.Name = "markCompleteButton";
            this.markCompleteButton.Size = new System.Drawing.Size(176, 25);
            this.markCompleteButton.TabIndex = 4;
            this.markCompleteButton.Text = "Mark Complete";
            this.markCompleteButton.UseVisualStyleBackColor = true;
            this.markCompleteButton.Click += new System.EventHandler(this.MarkCompleteClicked);
            // 
            // ShufflerTestForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(199, 174);
            this.Controls.Add(this.loadSessionButton);
            this.Controls.Add(this.newSessionButton);
            this.Controls.Add(this.saveSessionButton);
            this.Controls.Add(this.markCompleteButton);
            this.Controls.Add(this.nextGameButton);
            this.MaximizeBox = false;
            this.Name = "ShufflerTestForm";
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button newSessionButton;
        private System.Windows.Forms.Button loadSessionButton;
        private System.Windows.Forms.Button saveSessionButton;
        private System.Windows.Forms.Button nextGameButton;
        private System.Windows.Forms.Button markCompleteButton;
    }
}
