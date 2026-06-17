Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. "$PSScriptRoot\script.ps1"

$promosDejaVues = @{}
$surveillance = $false

$fenetre = New-Object System.Windows.Forms.Form
$fenetre.Text = "Dealabs"
$fenetre.Width = 900
$fenetre.Height = 560
$fenetre.StartPosition = "CenterScreen"

$labelMots = New-Object System.Windows.Forms.Label
$labelMots.Text = "Mots :"
$labelMots.Left = 20
$labelMots.Top = 20
$labelMots.Width = 60

$zoneMots = New-Object System.Windows.Forms.TextBox
$zoneMots.Left = 80
$zoneMots.Top = 18
$zoneMots.Width = 250
$zoneMots.Text = "ssd"

$labelPrix = New-Object System.Windows.Forms.Label
$labelPrix.Text = "Prix max :"
$labelPrix.Left = 350
$labelPrix.Top = 20
$labelPrix.Width = 70

$zonePrix = New-Object System.Windows.Forms.TextBox
$zonePrix.Left = 420
$zonePrix.Top = 18
$zonePrix.Width = 70
$zonePrix.Text = "0"

$labelHot = New-Object System.Windows.Forms.Label
$labelHot.Text = "Hot min :"
$labelHot.Left = 510
$labelHot.Top = 20
$labelHot.Width = 70

$zoneHot = New-Object System.Windows.Forms.TextBox
$zoneHot.Left = 580
$zoneHot.Top = 18
$zoneHot.Width = 60
$zoneHot.Text = "20"

$labelTemps = New-Object System.Windows.Forms.Label
$labelTemps.Text = "Scan sec. :"
$labelTemps.Left = 660
$labelTemps.Top = 20
$labelTemps.Width = 80

$zoneTemps = New-Object System.Windows.Forms.TextBox
$zoneTemps.Left = 740
$zoneTemps.Top = 18
$zoneTemps.Width = 60
$zoneTemps.Text = "300"

$boutonChercher = New-Object System.Windows.Forms.Button
$boutonChercher.Text = "Chercher"
$boutonChercher.Left = 20
$boutonChercher.Top = 55
$boutonChercher.Width = 110

$boutonSurveiller = New-Object System.Windows.Forms.Button
$boutonSurveiller.Text = "Surveiller"
$boutonSurveiller.Left = 140
$boutonSurveiller.Top = 55
$boutonSurveiller.Width = 110

$boutonOuvrir = New-Object System.Windows.Forms.Button
$boutonOuvrir.Text = "Ouvrir"
$boutonOuvrir.Left = 260
$boutonOuvrir.Top = 55
$boutonOuvrir.Width = 90
$boutonOuvrir.Enabled = $false

$tableau = New-Object System.Windows.Forms.ListView
$tableau.Left = 20
$tableau.Top = 95
$tableau.Width = 840
$tableau.Height = 380
$tableau.View = "Details"
$tableau.FullRowSelect = $true
$tableau.GridLines = $true
$tableau.Columns.Add("Mot", 70) | Out-Null
$tableau.Columns.Add("Titre", 490) | Out-Null
$tableau.Columns.Add("Prix", 90) | Out-Null
$tableau.Columns.Add("Hot", 70) | Out-Null
$tableau.Columns.Add("URL", 240) | Out-Null

$texteEtat = New-Object System.Windows.Forms.Label
$texteEtat.Left = 20
$texteEtat.Top = 490
$texteEtat.Width = 840
$texteEtat.Text = "Pret."

$timer = New-Object System.Windows.Forms.Timer

function Lire-Formulaire {
    $script:Mots = $zoneMots.Text -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    [decimal]$script:PrixMax = 0
    [int]$script:HotMin = 20
    [int]$script:Top = 10

    [decimal]::TryParse($zonePrix.Text, [ref]$script:PrixMax) | Out-Null
    [int]::TryParse($zoneHot.Text, [ref]$script:HotMin) | Out-Null

    $secondes = 300
    [int]::TryParse($zoneTemps.Text, [ref]$secondes) | Out-Null
    $timer.Interval = [Math]::Max(30, $secondes) * 1000
}

function Remplir-Tableau {
    param([object[]]$promos)

    $tableau.Items.Clear()

    foreach ($promo in $promos) {
        $prix = if ($null -ne $promo.Prix) { "$($promo.Prix) EUR" } else { "-" }

        $ligne = New-Object System.Windows.Forms.ListViewItem($promo.Mot)
        $ligne.SubItems.Add($promo.Titre) | Out-Null
        $ligne.SubItems.Add($prix) | Out-Null
        $ligne.SubItems.Add("$($promo.Hot) deg") | Out-Null
        $ligne.SubItems.Add($promo.Url) | Out-Null
        $tableau.Items.Add($ligne) | Out-Null
    }
}

function Lancer-Recherche-Interface {
    param([bool]$notifierSeulementNouveau)

    Lire-Formulaire
    $texteEtat.Text = "Recherche..."
    $fenetre.Refresh()

    $promos = Faire-Recherche
    Remplir-Tableau $promos

    foreach ($promo in $promos) {
        if (-not $promosDejaVues.ContainsKey($promo.Url)) {
            $promosDejaVues[$promo.Url] = $true

            if ($notifierSeulementNouveau) {
                Notifier "Nouvelle promo : $($promo.Hot) deg - $($promo.Titre)"
            }
        }
    }

    if (-not $notifierSeulementNouveau -and $promos.Count -gt 0) {
        Notifier "$($promos[0].Hot) deg - $($promos[0].Titre)"
    }

    $texteEtat.Text = "$(Get-Date -Format 'HH:mm:ss') - $($promos.Count) promo(s)."
}

$boutonChercher.Add_Click({
    Lancer-Recherche-Interface $false
})

$boutonSurveiller.Add_Click({
    if ($surveillance) {
        $timer.Stop()
        $script:surveillance = $false
        $boutonSurveiller.Text = "Surveiller"
        $texteEtat.Text = "Surveillance arretee."
    }
    else {
        Lire-Formulaire
        $script:surveillance = $true
        $boutonSurveiller.Text = "Arreter"
        Lancer-Recherche-Interface $false
        $timer.Start()
    }
})

$timer.Add_Tick({
    Lancer-Recherche-Interface $true
})

$tableau.Add_SelectedIndexChanged({
    $boutonOuvrir.Enabled = $tableau.SelectedItems.Count -gt 0
})

$boutonOuvrir.Add_Click({
    if ($tableau.SelectedItems.Count -gt 0) {
        Start-Process $tableau.SelectedItems[0].SubItems[4].Text
    }
})

$fenetre.Controls.Add($labelMots)
$fenetre.Controls.Add($zoneMots)
$fenetre.Controls.Add($labelPrix)
$fenetre.Controls.Add($zonePrix)
$fenetre.Controls.Add($labelHot)
$fenetre.Controls.Add($zoneHot)
$fenetre.Controls.Add($labelTemps)
$fenetre.Controls.Add($zoneTemps)
$fenetre.Controls.Add($boutonChercher)
$fenetre.Controls.Add($boutonSurveiller)
$fenetre.Controls.Add($boutonOuvrir)
$fenetre.Controls.Add($tableau)
$fenetre.Controls.Add($texteEtat)

[void]$fenetre.ShowDialog()
