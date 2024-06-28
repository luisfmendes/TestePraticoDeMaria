using Microsoft.Reporting.Map.WebForms.BingMaps;
using Microsoft.Reporting.WinForms;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using TestePraticoDeMaria.Bases;
using TestePraticoDeMaria.Negócios;
using TestePraticoDeMaria.Relatorios;

namespace TestePraticoDeMaria.Apresentacao
{
    public partial class frmRelatorio : frmBase
    {
        string sNomeReport = "";
        DataTable dDados = new DataTable();
        public frmRelatorio(string report, DataTable dados)
        {
            InitializeComponent();
            try
            {
                sNomeReport = report;
                dDados = dados;
                WindowState = FormWindowState.Normal;
                Height = Screen.PrimaryScreen.WorkingArea.Height;
                Width = Screen.PrimaryScreen.WorkingArea.Width;
                Left = Screen.PrimaryScreen.WorkingArea.Left;
                Top = Screen.PrimaryScreen.WorkingArea.Top;
                MinimumSize = Size;
                MaximumSize = Size;
                Refresh();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }

        private void frmRelatorio_Load(object sender, EventArgs e)
        {
            try
            {
                reportViewer.LocalReport.ReportEmbeddedResource = $"TestePraticoDeMaria.Relatorios.{sNomeReport}";
                reportViewer.LocalReport.DataSources.Clear();
                reportViewer.LocalReport.DataSources.Add(new ReportDataSource("DataSet1", dDados));
                reportViewer.SetDisplayMode(DisplayMode.PrintLayout);
                this.reportViewer.RefreshReport();
            }
            catch (Exception ex)
            {
                Mensagem.Erro(ex.Message, "Erro");
            }
        }
    }
}
