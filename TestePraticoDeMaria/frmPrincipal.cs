using Microsoft.Win32;
using System;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using TestePraticoDeMaria;
using TestePraticoDeMaria.Apresentacao;
using TestePraticoDeMaria.Bases;
using TestePraticoDeMaria.Negócios;

namespace TestePraticoDeMaria
{
    public partial class frmPrincipal : frmBase
    {
        #region  Formulários que vão ser abertos pelo botões

        frmProdutos frmProd;
        frmConsultaClientes frmConsultaCli;
        frmClientes frmCli;
        frmConsultaProd frmConsultProd;
        frmFornecedor frmForn;
        frmConsultaFornecedor frmConsultForn;
        frmVenda formVenda;
        frmCompras formCompras;
        frmConsultaCompra formComprasConsulta;
        #endregion


        public frmPrincipal()
        {
            InitializeComponent();
        }

        private void frmPrincipal_Load(object sender, EventArgs e)
        {
            try
            {
                //Feito isso para que o formulário siga a barra de ferramentas do windows ficando somente no tamanho da area de trabalho
                WindowState = FormWindowState.Normal;
                Height = Screen.PrimaryScreen.WorkingArea.Height;
                Width = Screen.PrimaryScreen.WorkingArea.Width;
                Left = Screen.PrimaryScreen.WorkingArea.Left;
                Top = Screen.PrimaryScreen.WorkingArea.Top;
                MinimumSize = Size;
                MaximumSize = Size;
                Refresh();
                //---------------------------


                SuperTabGeral.SelectedItem = tabCadastros;
                string sWallPaper = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", false).GetValue("WallPaper").ToString();
                if (System.IO.File.Exists(sWallPaper))
                {
                    panel2.BackgroundImage = new Bitmap(sWallPaper).Resize(Width, Height);
                }

                //Verificando os arquivos de conexão
                string sCaminhoArquivo = Path.Combine(Application.StartupPath, VariaveisGlobal.sNomeArqConexao);
                if (!File.Exists(sCaminhoArquivo))
                {
                    File.WriteAllText(sCaminhoArquivo, "");
                }


                string[] conteudo = File.ReadAllLines(sCaminhoArquivo);

                if (conteudo.Length > 0 && conteudo.Length == 5)
                {
                    VariaveisGlobal.strConexao = $"Server={conteudo[0]};Port={conteudo[1]};User Id={conteudo[2]};Password={conteudo[3]};Database={conteudo[4]};CommandTimeout=240;Pooling=false;";
                }
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void timerHora_Tick(object sender, EventArgs e)
        {
            try
            {
                lblHora.Text = DateTime.Now.ToLongDateString().PrimeiraPalavraMaiuscula() + " " + DateTime.Now.ToString("hh:mm:ss");
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnMinimizar_Click(object sender, EventArgs e)
        {
            try
            {
                this.WindowState = FormWindowState.Minimized;
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnCadCliente_Click(object sender, EventArgs e)
        {
            try
            {
                if(Application.OpenForms.OfType<frmClientes>().Count() > 0)
                {
                    frmCli.BringToFront();
                    frmCli.Activate();
                    return;
                }
                verificaConexao();
                frmCli = new frmClientes(VariaveisGlobal.TipoOperacao.Gravar);
                frmCli.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }
        
        private void btnVerCliente_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmConsultaClientes>().Count() > 0)
                {
                    frmConsultaCli.BringToFront();
                    frmConsultaCli.Activate();
                    return;
                }
                verificaConexao();
                frmConsultaCli = new frmConsultaClientes();
                frmConsultaCli.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }
       
        private void btnCadProduto_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmProdutos>().Count() > 0)
                {
                    frmProd.BringToFront();
                    frmProd.Activate();
                    return;
                }
                verificaConexao();
                frmProd = new frmProdutos(VariaveisGlobal.TipoOperacao.Gravar);
                frmProd.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnVerProduto_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmConsultaProd>().Count() > 0)
                {
                    frmConsultProd.BringToFront();
                    frmConsultProd.Activate();
                    return;
                }
                verificaConexao();
                frmConsultProd = new frmConsultaProd();
                frmConsultProd.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnCadFornecedor_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmFornecedor>().Count() > 0)
                {
                    frmForn.BringToFront();
                    frmForn.Activate();
                    return;
                }
                verificaConexao();
                frmForn = new frmFornecedor(VariaveisGlobal.TipoOperacao.Gravar);
                frmForn.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }

        }

        private void btnVerFornecedor_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmConsultaFornecedor>().Count() > 0)
                {
                    frmConsultForn.BringToFront();
                    frmConsultForn.Activate();
                    return;
                }
                verificaConexao();
                frmConsultForn = new frmConsultaFornecedor();
                frmConsultForn.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }


        private void btnVenda_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmVenda>().Count() > 0)
                {
                    formVenda.BringToFront();
                    formVenda.Activate();
                    return;
                }
                verificaConexao();
                formVenda = new frmVenda();
                formVenda.WindowState = FormWindowState.Maximized;
                formVenda.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnCompra_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmCompras>().Count() > 0)
                {
                    formCompras.BringToFront();
                    formCompras.Activate();
                    return;
                }
                verificaConexao();
                formCompras = new frmCompras();
                formCompras.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void btnConsultaCompra_Click(object sender, EventArgs e)
        {
            try
            {
                if (Application.OpenForms.OfType<frmConsultaCompra>().Count() > 0)
                {
                    formComprasConsulta.BringToFront();
                    formComprasConsulta.Activate();
                    return;
                }
                verificaConexao();
                formComprasConsulta = new frmConsultaCompra();
                formComprasConsulta.Show();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void verificaConexao()
        {
            try
            {
                if(!new clsConexao().TestaConexao())
                {
                    throw new Exception("Não é possível entrar pois não há conexão com o banco de dados");
                }
            }
            catch
            {
                throw;
            }
        }

        private void btnConfiguraConexao_Click(object sender, EventArgs e)
        {
            try
            {
                frmConfiguraConexao frm = new frmConfiguraConexao();
                frm.ShowDialog();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }

        }

        private void button1_Click(object sender, EventArgs e)
        {
            
        }
    }
}
