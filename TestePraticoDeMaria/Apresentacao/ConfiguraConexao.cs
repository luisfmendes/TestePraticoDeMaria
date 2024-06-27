using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using TestTCC.Bases;
using TestTCC.Negócios;

namespace TestePraticoDeMaria.Apresentacao
{
    public partial class ConfiguraConexao : frmBase
    {
        public ConfiguraConexao()
        {
            InitializeComponent();
        }

        private void ConfiguraConexao_Load(object sender, EventArgs e)
        {
            try
            {
                /*
                 * ESTRUTURA DO ARQUIVO DE CONEXAO
                [0] IP
                [1] Porta
                [2] Usuario
                [3] Senha
                [4] NomeBanco
                 */
                string sCaminhoArquivo = Path.Combine(Application.ExecutablePath, VariaveisGlobal.sNomeArqConexao);
                if (!File.Exists(sCaminhoArquivo))
                {
                    File.Create(sCaminhoArquivo);
                }

                string[] conteudo = File.ReadAllLines(sCaminhoArquivo);

                if(conteudo.Length > 0 && conteudo.Length == 5)
                {
                    txtIp.Text = conteudo[0];
                    txtPorta.Text = conteudo[1];
                    txtUsuario.Text = conteudo[2];
                    txtSenha.Text = conteudo[3];
                    txtNomeBase.Text = conteudo[4];
                }

            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void txtPorta_KeyPress(object sender, KeyPressEventArgs e)
        {
            try
            {
                //Impede que digite algo alem de numeros
                e.Handled = !char.IsDigit(e.KeyChar) && !char.IsControl(e.KeyChar);
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void picVerSenha_MouseDown(object sender, MouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    txtSenha.PasswordChar = (char)00;
                }
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void picVerSenha_MouseUp(object sender, MouseEventArgs e)
        {
            try
            {
                if (e.Button == MouseButtons.Left)
                {
                    txtSenha.PasswordChar = (char)42;
                }
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnTestarConexao_Click(object sender, EventArgs e)
        {
            try
            {                
                if(new clsConexao().TestaConexao($"Server={txtIp.Text};Port={txtPorta.Text};User Id={txtUsuario.Text};Password={txtSenha.Text};Database={txtNomeBase.Text};CommandTimeout=240;Pooling=false;"))
                {
                    btnGravar.Enabled = true;
                }
                else
                {
                    Mensagem.Alerta("Falha ao se conectar com o banco de dados","Atenção");
                }
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }
    }
}
