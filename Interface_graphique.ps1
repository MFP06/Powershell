Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$dossierScript = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $dossierScript

. "$dossierScript\script.ps1"

function Convertir-Mots {
    param([string]$Texte)

    $mots = $Texte -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($mots.Count -eq 0) {
        return @("ssd")
    }

    return @($mots)
}

function Ajouter-Resultats {
    param($Resultats)

    $liste.Items.Clear()

    foreach ($promo in $Resultats) {
        $item = New-Object System.Windows.Forms.ListViewItem($promo.Mot)
        [void]$item.SubItems.Add($promo.Titre)
        [void]$item.SubItems.Add($(if ($null -eq $promo.Prix) { "" } else { "$($promo.Prix) EUR" }))
        [void]$item.SubItems.Add("$($promo.Hot)")
        [void]$item.SubItems.Add($promo.Url)
        $item.Tag = $promo
        [void]$liste.Items.Add($item)
    }
}

function Lancer-Recherche {
    $script:Mots = Convertir-Mots $champMots.Text
    $script:PrixMax = [decimal]$champPrix.Value
    $script:HotMin = [int]$champHot.Value
    $script:Top = [int]$champTop.Value

    $boutonChercher.Enabled = $false
    $boutonSurveiller.Enabled = $false
    $statut.Text = "Recherche en cours..."
    $form.Refresh()

    try {
        $resultats = Faire-Recherche
        Ajouter-Resultats $resultats
        $statut.Text = "$(Get-Date -Format 'HH:mm:ss') - $($resultats.Count) promo(s) trouvee(s)."
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Erreur", "OK", "Error") | Out-Null
        $statut.Text = "Erreur pendant la recherche."
    }
    finally {
        $boutonChercher.Enabled = $true
        $boutonSurveiller.Enabled = $true
    }
}

function Basculer-Surveillance {
    if ($timer.Enabled) {
        $timer.Stop()
        $boutonSurveiller.Text = "Surveiller"
        $statut.Text = "Surveillance arretee."
        return
    }

    $intervalle = [int]$champIntervalle.Value
    $timer.Interval = $intervalle * 1000
    $script:PromosDejaVues = @{}

    Lancer-Recherche

    foreach ($item in $liste.Items) {
        if ($item.Tag.Url) {
            $script:PromosDejaVues[$item.Tag.Url] = $true
        }
    }

    $timer.Start()
    $boutonSurveiller.Text = "Arreter"
    $statut.Text = "Surveillance active toutes les $intervalle secondes."
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Dealabs - Recherche de promos"
$form.Size = New-Object System.Drawing.Size(980, 620)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(850, 520)

$police = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Font = $police

$panelHaut = New-Object System.Windows.Forms.Panel
$panelHaut.Dock = "Top"
$panelHaut.Height = 96
$panelHaut.Padding = New-Object System.Windows.Forms.Padding(10)
$form.Controls.Add($panelHaut)

$labelMots = New-Object System.Windows.Forms.Label
$labelMots.Text = "Mots"
$labelMots.Location = New-Object System.Drawing.Point(10, 13)
$labelMots.AutoSize = $true
$panelHaut.Controls.Add($labelMots)

$champMots = New-Object System.Windows.Forms.TextBox
$champMots.Text = "ssd"
$champMots.Location = New-Object System.Drawing.Point(10, 35)
$champMots.Size = New-Object System.Drawing.Size(220, 24)
$panelHaut.Controls.Add($champMots)

$labelPrix = New-Object System.Windows.Forms.Label
$labelPrix.Text = "Prix max"
$labelPrix.Location = New-Object System.Drawing.Point(245, 13)
$labelPrix.AutoSize = $true
$panelHaut.Controls.Add($labelPrix)

$champPrix = New-Object System.Windows.Forms.NumericUpDown
$champPrix.Location = New-Object System.Drawing.Point(245, 35)
$champPrix.Size = New-Object System.Drawing.Size(95, 24)
$champPrix.Maximum = 100000
$champPrix.DecimalPlaces = 2
$champPrix.Value = 0
$panelHaut.Controls.Add($champPrix)

$labelHot = New-Object System.Windows.Forms.Label
$labelHot.Text = "Hot min"
$labelHot.Location = New-Object System.Drawing.Point(355, 13)
$labelHot.AutoSize = $true
$panelHaut.Controls.Add($labelHot)

$champHot = New-Object System.Windows.Forms.NumericUpDown
$champHot.Location = New-Object System.Drawing.Point(355, 35)
$champHot.Size = New-Object System.Drawing.Size(80, 24)
$champHot.Maximum = 10000
$champHot.Minimum = -1000
$champHot.Value = 20
$panelHaut.Controls.Add($champHot)

$labelTop = New-Object System.Windows.Forms.Label
$labelTop.Text = "Top"
$labelTop.Location = New-Object System.Drawing.Point(450, 13)
$labelTop.AutoSize = $true
$panelHaut.Controls.Add($labelTop)

$champTop = New-Object System.Windows.Forms.NumericUpDown
$champTop.Location = New-Object System.Drawing.Point(450, 35)
$champTop.Size = New-Object System.Drawing.Size(70, 24)
$champTop.Minimum = 1
$champTop.Maximum = 100
$champTop.Value = 10
$panelHaut.Controls.Add($champTop)

$labelIntervalle = New-Object System.Windows.Forms.Label
$labelIntervalle.Text = "Scan sec."
$labelIntervalle.Location = New-Object System.Drawing.Point(535, 13)
$labelIntervalle.AutoSize = $true
$panelHaut.Controls.Add($labelIntervalle)

$champIntervalle = New-Object System.Windows.Forms.NumericUpDown
$champIntervalle.Location = New-Object System.Drawing.Point(535, 35)
$champIntervalle.Size = New-Object System.Drawing.Size(90, 24)
$champIntervalle.Minimum = 30
$champIntervalle.Maximum = 86400
$champIntervalle.Value = 300
$panelHaut.Controls.Add($champIntervalle)

$boutonChercher = New-Object System.Windows.Forms.Button
$boutonChercher.Text = "Chercher"
$boutonChercher.Location = New-Object System.Drawing.Point(645, 32)
$boutonChercher.Size = New-Object System.Drawing.Size(95, 30)
$boutonChercher.Add_Click({ Lancer-Recherche })
$panelHaut.Controls.Add($boutonChercher)

$boutonSurveiller = New-Object System.Windows.Forms.Button
$boutonSurveiller.Text = "Surveiller"
$boutonSurveiller.Location = New-Object System.Drawing.Point(750, 32)
$boutonSurveiller.Size = New-Object System.Drawing.Size(95, 30)
$boutonSurveiller.Add_Click({ Basculer-Surveillance })
$panelHaut.Controls.Add($boutonSurveiller)

$boutonOuvrir = New-Object System.Windows.Forms.Button
$boutonOuvrir.Text = "Ouvrir"
$boutonOuvrir.Location = New-Object System.Drawing.Point(855, 32)
$boutonOuvrir.Size = New-Object System.Drawing.Size(85, 30)
$boutonOuvrir.Add_Click({
    if ($liste.SelectedItems.Count -eq 0) {
        return
    }

    $url = $liste.SelectedItems[0].Tag.Url
    if ($url) {
        Start-Process $url
    }
})
$panelHaut.Controls.Add($boutonOuvrir)

$liste = New-Object System.Windows.Forms.ListView
$liste.Dock = "Fill"
$liste.View = "Details"
$liste.FullRowSelect = $true
$liste.GridLines = $true
[void]$liste.Columns.Add("Mot", 90)
[void]$liste.Columns.Add("Titre", 500)
[void]$liste.Columns.Add("Prix", 90)
[void]$liste.Columns.Add("Hot", 70)
[void]$liste.Columns.Add("Url", 280)
$form.Controls.Add($liste)

$statut = New-Object System.Windows.Forms.Label
$statut.Dock = "Bottom"
$statut.Height = 28
$statut.Text = "Pret."
$statut.Padding = New-Object System.Windows.Forms.Padding(10, 6, 10, 0)
$form.Controls.Add($statut)

$timer = New-Object System.Windows.Forms.Timer
$timer.Add_Tick({
    $anciens = $script:PromosDejaVues
    Lancer-Recherche

    foreach ($item in $liste.Items) {
        $promo = $item.Tag
        if ($promo.Url -and -not $anciens.ContainsKey($promo.Url)) {
            $anciens[$promo.Url] = $true
            Notifier "Nouvelle promo : $($promo.Hot) deg - $($promo.Titre)"
        }
    }
})

[void]$form.ShowDialog()
