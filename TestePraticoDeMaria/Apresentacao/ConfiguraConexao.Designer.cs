namespace TestePraticoDeMaria.Apresentacao
{
    partial class ConfiguraConexao
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
            this.btnTestarConexao = new System.Windows.Forms.Button();
            this.btnGravar = new System.Windows.Forms.Button();
            this.txtPorta = new DevComponents.DotNetBar.Controls.TextBoxX();
            this.label4 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.txtIp = new DevComponents.DotNetBar.Controls.TextBoxX();
            this.txtUsuario = new DevComponents.DotNetBar.Controls.TextBoxX();
            this.label3 = new System.Windows.Forms.Label();
            this.txtSenha = new DevComponents.DotNetBar.Controls.TextBoxX();
            this.label5 = new System.Windows.Forms.Label();
            this.txtNomeBase = new DevComponents.DotNetBar.Controls.TextBoxX();
            this.label6 = new System.Windows.Forms.Label();
            this.picVerSenha = new System.Windows.Forms.PictureBox();
            this.panel1.SuspendLayout();
            this.panel2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picVerSenha)).BeginInit();
            this.SuspendLayout();
            // 
            // label1
            // 
            this.label1.Text = "Configurar Conexão";
            // 
            // btnFechar
            // 
            this.btnFechar.TabIndex = 8;
            this.btnFechar.TabStop = false;
            // 
            // btnSair
            // 
            this.btnSair.TabStop = false;
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.picVerSenha);
            this.panel2.Controls.Add(this.txtNomeBase);
            this.panel2.Controls.Add(this.label6);
            this.panel2.Controls.Add(this.txtSenha);
            this.panel2.Controls.Add(this.label5);
            this.panel2.Controls.Add(this.txtUsuario);
            this.panel2.Controls.Add(this.label3);
            this.panel2.Controls.Add(this.txtIp);
            this.panel2.Controls.Add(this.label2);
            this.panel2.Controls.Add(this.label4);
            this.panel2.Controls.Add(this.txtPorta);
            this.panel2.Controls.Add(this.btnGravar);
            this.panel2.Controls.Add(this.btnTestarConexao);
            this.panel2.Controls.SetChildIndex(this.btnFechar, 0);
            this.panel2.Controls.SetChildIndex(this.btnTestarConexao, 0);
            this.panel2.Controls.SetChildIndex(this.btnGravar, 0);
            this.panel2.Controls.SetChildIndex(this.txtPorta, 0);
            this.panel2.Controls.SetChildIndex(this.label4, 0);
            this.panel2.Controls.SetChildIndex(this.label2, 0);
            this.panel2.Controls.SetChildIndex(this.txtIp, 0);
            this.panel2.Controls.SetChildIndex(this.label3, 0);
            this.panel2.Controls.SetChildIndex(this.txtUsuario, 0);
            this.panel2.Controls.SetChildIndex(this.label5, 0);
            this.panel2.Controls.SetChildIndex(this.txtSenha, 0);
            this.panel2.Controls.SetChildIndex(this.label6, 0);
            this.panel2.Controls.SetChildIndex(this.txtNomeBase, 0);
            this.panel2.Controls.SetChildIndex(this.picVerSenha, 0);
            // 
            // btnTestarConexao
            // 
            this.btnTestarConexao.BackColor = System.Drawing.Color.Moccasin;
            this.btnTestarConexao.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnTestarConexao.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnTestarConexao.ForeColor = System.Drawing.Color.DarkGoldenrod;
            this.btnTestarConexao.Location = new System.Drawing.Point(474, 281);
            this.btnTestarConexao.Name = "btnTestarConexao";
            this.btnTestarConexao.Size = new System.Drawing.Size(173, 35);
            this.btnTestarConexao.TabIndex = 6;
            this.btnTestarConexao.Text = "Testar Conexão";
            this.btnTestarConexao.UseVisualStyleBackColor = false;
            this.btnTestarConexao.Click += new System.EventHandler(this.btnTestarConexao_Click);
            // 
            // btnGravar
            // 
            this.btnGravar.BackColor = System.Drawing.Color.Honeydew;
            this.btnGravar.Enabled = false;
            this.btnGravar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnGravar.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnGravar.ForeColor = System.Drawing.Color.DarkGreen;
            this.btnGravar.Location = new System.Drawing.Point(682, 403);
            this.btnGravar.Name = "btnGravar";
            this.btnGravar.Size = new System.Drawing.Size(105, 42);
            this.btnGravar.TabIndex = 7;
            this.btnGravar.Text = "Gravar";
            this.btnGravar.UseVisualStyleBackColor = false;
            // 
            // txtPorta
            // 
            this.txtPorta.BackColor = System.Drawing.Color.White;
            // 
            // 
            // 
            this.txtPorta.Border.Class = "TextBoxBorder";
            this.txtPorta.Border.CornerType = DevComponents.DotNetBar.eCornerType.Square;
            this.txtPorta.DisabledBackColor = System.Drawing.Color.White;
            this.txtPorta.FocusHighlightEnabled = true;
            this.txtPorta.ForeColor = System.Drawing.Color.Black;
            this.txtPorta.Location = new System.Drawing.Point(548, 69);
            this.txtPorta.Name = "txtPorta";
            this.txtPorta.PreventEnterBeep = true;
            this.txtPorta.Size = new System.Drawing.Size(99, 26);
            this.txtPorta.TabIndex = 2;
            this.txtPorta.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.txtPorta_KeyPress);
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.BackColor = System.Drawing.Color.Transparent;
            this.label4.ForeColor = System.Drawing.Color.Black;
            this.label4.Location = new System.Drawing.Point(22, 45);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(89, 20);
            this.label4.TabIndex = 18;
            this.label4.Text = "Ip Servidor:";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.BackColor = System.Drawing.Color.Transparent;
            this.label2.ForeColor = System.Drawing.Color.Black;
            this.label2.Location = new System.Drawing.Point(544, 46);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(51, 20);
            this.label2.TabIndex = 20;
            this.label2.Text = "Porta:";
            // 
            // txtIp
            // 
            this.txtIp.BackColor = System.Drawing.Color.White;
            // 
            // 
            // 
            this.txtIp.Border.Class = "TextBoxBorder";
            this.txtIp.Border.CornerType = DevComponents.DotNetBar.eCornerType.Square;
            this.txtIp.DisabledBackColor = System.Drawing.Color.White;
            this.txtIp.FocusHighlightEnabled = true;
            this.txtIp.ForeColor = System.Drawing.Color.Black;
            this.txtIp.Location = new System.Drawing.Point(26, 69);
            this.txtIp.Name = "txtIp";
            this.txtIp.PreventEnterBeep = true;
            this.txtIp.Size = new System.Drawing.Size(516, 26);
            this.txtIp.TabIndex = 1;
            // 
            // txtUsuario
            // 
            this.txtUsuario.BackColor = System.Drawing.Color.White;
            // 
            // 
            // 
            this.txtUsuario.Border.Class = "TextBoxBorder";
            this.txtUsuario.Border.CornerType = DevComponents.DotNetBar.eCornerType.Square;
            this.txtUsuario.DisabledBackColor = System.Drawing.Color.White;
            this.txtUsuario.FocusHighlightEnabled = true;
            this.txtUsuario.ForeColor = System.Drawing.Color.Black;
            this.txtUsuario.Location = new System.Drawing.Point(26, 124);
            this.txtUsuario.Name = "txtUsuario";
            this.txtUsuario.PreventEnterBeep = true;
            this.txtUsuario.Size = new System.Drawing.Size(621, 26);
            this.txtUsuario.TabIndex = 3;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.BackColor = System.Drawing.Color.Transparent;
            this.label3.ForeColor = System.Drawing.Color.Black;
            this.label3.Location = new System.Drawing.Point(22, 100);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(68, 20);
            this.label3.TabIndex = 22;
            this.label3.Text = "Usuário:";
            // 
            // txtSenha
            // 
            this.txtSenha.BackColor = System.Drawing.Color.White;
            // 
            // 
            // 
            this.txtSenha.Border.Class = "TextBoxBorder";
            this.txtSenha.Border.CornerType = DevComponents.DotNetBar.eCornerType.Square;
            this.txtSenha.DisabledBackColor = System.Drawing.Color.White;
            this.txtSenha.FocusHighlightEnabled = true;
            this.txtSenha.ForeColor = System.Drawing.Color.Black;
            this.txtSenha.Location = new System.Drawing.Point(26, 181);
            this.txtSenha.Name = "txtSenha";
            this.txtSenha.PreventEnterBeep = true;
            this.txtSenha.Size = new System.Drawing.Size(621, 26);
            this.txtSenha.TabIndex = 4;
            this.txtSenha.UseSystemPasswordChar = true;
            // 
            // label5
            // 
            this.label5.AutoSize = true;
            this.label5.BackColor = System.Drawing.Color.Transparent;
            this.label5.ForeColor = System.Drawing.Color.Black;
            this.label5.Location = new System.Drawing.Point(22, 157);
            this.label5.Name = "label5";
            this.label5.Size = new System.Drawing.Size(60, 20);
            this.label5.TabIndex = 24;
            this.label5.Text = "Senha:";
            // 
            // txtNomeBase
            // 
            this.txtNomeBase.BackColor = System.Drawing.Color.White;
            // 
            // 
            // 
            this.txtNomeBase.Border.Class = "TextBoxBorder";
            this.txtNomeBase.Border.CornerType = DevComponents.DotNetBar.eCornerType.Square;
            this.txtNomeBase.DisabledBackColor = System.Drawing.Color.White;
            this.txtNomeBase.FocusHighlightEnabled = true;
            this.txtNomeBase.ForeColor = System.Drawing.Color.Black;
            this.txtNomeBase.Location = new System.Drawing.Point(26, 236);
            this.txtNomeBase.Name = "txtNomeBase";
            this.txtNomeBase.PreventEnterBeep = true;
            this.txtNomeBase.Size = new System.Drawing.Size(621, 26);
            this.txtNomeBase.TabIndex = 5;
            // 
            // label6
            // 
            this.label6.AutoSize = true;
            this.label6.BackColor = System.Drawing.Color.Transparent;
            this.label6.ForeColor = System.Drawing.Color.Black;
            this.label6.Location = new System.Drawing.Point(22, 212);
            this.label6.Name = "label6";
            this.label6.Size = new System.Drawing.Size(116, 20);
            this.label6.TabIndex = 26;
            this.label6.Text = "Nome da base:";
            // 
            // picVerSenha
            // 
            this.picVerSenha.BackgroundImage = global::TestePraticoDeMaria.Properties.Resources.eye;
            this.picVerSenha.BackgroundImageLayout = System.Windows.Forms.ImageLayout.Zoom;
            this.picVerSenha.Location = new System.Drawing.Point(653, 181);
            this.picVerSenha.Name = "picVerSenha";
            this.picVerSenha.Size = new System.Drawing.Size(28, 26);
            this.picVerSenha.TabIndex = 28;
            this.picVerSenha.TabStop = false;
            this.picVerSenha.MouseDown += new System.Windows.Forms.MouseEventHandler(this.picVerSenha_MouseDown);
            this.picVerSenha.MouseUp += new System.Windows.Forms.MouseEventHandler(this.picVerSenha_MouseUp);
            // 
            // ConfiguraConexao
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Name = "ConfiguraConexao";
            this.Text = "ConfiguraConexao";
            this.Load += new System.EventHandler(this.ConfiguraConexao_Load);
            this.panel1.ResumeLayout(false);
            this.panel2.ResumeLayout(false);
            this.panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picVerSenha)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnTestarConexao;
        private System.Windows.Forms.Button btnGravar;
        private DevComponents.DotNetBar.Controls.TextBoxX txtPorta;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Label label2;
        private DevComponents.DotNetBar.Controls.TextBoxX txtIp;
        private DevComponents.DotNetBar.Controls.TextBoxX txtSenha;
        private System.Windows.Forms.Label label5;
        private DevComponents.DotNetBar.Controls.TextBoxX txtUsuario;
        private System.Windows.Forms.Label label3;
        private DevComponents.DotNetBar.Controls.TextBoxX txtNomeBase;
        private System.Windows.Forms.Label label6;
        private System.Windows.Forms.PictureBox picVerSenha;
    }
}