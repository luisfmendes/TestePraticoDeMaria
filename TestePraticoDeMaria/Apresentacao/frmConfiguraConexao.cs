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
using TestePraticoDeMaria.Bases;
using TestePraticoDeMaria.Negócios;
using static System.Windows.Forms.VisualStyles.VisualStyleElement;

namespace TestePraticoDeMaria.Apresentacao
{
    public partial class frmConfiguraConexao : frmBase
    {        
        string sCaminhoArquivo = Path.Combine(Application.StartupPath, VariaveisGlobal.sNomeArqConexao);
        public frmConfiguraConexao()
        {
            InitializeComponent();
        }

        private void ConfiguraConexao_Load(object sender, EventArgs e)
        {
            try
            {
                //Inicia com a senha com bolinhas
                //txtSenha.PasswordChar = (char)42;
                /*
                 * ESTRUTURA DO ARQUIVO DE CONEXAO
                [0] IP
                [1] Porta
                [2] Usuario
                [3] Senha
                [4] NomeBanco
                 */

                if (!File.Exists(sCaminhoArquivo))
                {
                    File.WriteAllText(sCaminhoArquivo, "");
                }
                //Le o arquivo da pasta com os dados do banco e preenche o formulário caso exista o arquivo e ele esteja com os parametros corretos
                string[] conteudo = File.ReadAllLines(sCaminhoArquivo);

                if (conteudo.Length > 0 && conteudo.Length == 5)
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
                    txtSenha.UseSystemPasswordChar = false;
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
                    txtSenha.UseSystemPasswordChar = true;
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
                testaConexao(true);
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private bool testaConexao(bool bMensagem = false)
        {
            try
            {
                if (TestaCampos())
                {
                    //Testa a conexão com o banco antes de permitir a gravação
                    if (new clsConexao().TestaConexao($"Server={txtIp.Text};Port={txtPorta.Text};User Id={txtUsuario.Text};Password={txtSenha.Text};Database={txtNomeBase.Text};CommandTimeout=240;Pooling=false;"))
                    {
                        btnGravar.Enabled = true;
                        if (bMensagem)
                        {
                            Mensagem.Informacao("Conectado com sucesso!", "Sucesso");
                        }
                        return true;
                    }
                    else
                    {
                        Mensagem.Alerta("Falha ao se conectar com o banco de dados", "Atenção");
                    }
                }
            }
            catch
            {
                throw;
            }
            return false;
        }

        private void btnGravar_Click(object sender, EventArgs e)
        {
            try
            {
                //Testa a conexão novamente para garantir caso a pessoal tenha mudado antes de clicar no gravar
                if (testaConexao())
                {

                    if (TestaCampos())
                    {
                        if (!File.Exists(sCaminhoArquivo))
                        {
                            File.WriteAllText(sCaminhoArquivo, "");
                        }

                        //Adiciono cada elemento em uma linha do arquivo
                        StringBuilder sb = new StringBuilder();
                        sb.AppendLine(txtIp.Text);
                        sb.AppendLine(txtPorta.Text);
                        sb.AppendLine(txtUsuario.Text);
                        sb.AppendLine(txtSenha.Text);
                        sb.AppendLine(txtNomeBase.Text);

                        File.WriteAllText(sCaminhoArquivo, sb.ToString());
                        VariaveisGlobal.strConexao = $"Server={txtIp.Text};Port={txtPorta.Text};User Id={txtUsuario.Text};Password={txtSenha.Text};Database={txtNomeBase.Text};CommandTimeout=240;Pooling=false;";
                        Mensagem.Informacao("Gravado com sucesso!", "Sucesso");
                        Close();
                    }
                }
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        /// <summary>
        /// Testa os campos da tela para que a conexão seja feita
        /// </summary>
        /// <returns></returns>
        private bool TestaCampos()
        {
            try
            {
                if (string.IsNullOrEmpty(txtIp.Text))
                {
                    Mensagem.Alerta("Campo Ip não preenchido.", "Atenção");
                    txtIp.Focus();
                    return false;
                }
                else if (string.IsNullOrEmpty(txtPorta.Text))
                {
                    Mensagem.Alerta("Campo Porta não preenchido.", "Atenção");
                    txtPorta.Focus();
                    return false;
                }
                else if (string.IsNullOrEmpty(txtUsuario.Text))
                {
                    Mensagem.Alerta("Campo Usuário não preenchido.", "Atenção");
                    txtUsuario.Focus();
                    return false;
                }
                else if (string.IsNullOrEmpty(txtSenha.Text))
                {
                    Mensagem.Alerta("Campo Senha não preenchido.", "Atenção");
                    txtSenha.Focus();
                    return false;
                }
                else if (string.IsNullOrEmpty(txtNomeBase.Text))
                {
                    Mensagem.Alerta("Campo Nome da base não preenchido.", "Atenção");
                    txtNomeBase.Focus();
                    return false;
                }

            }
            catch
            {
                throw;                
            }
            return true;
        }
    }
}
