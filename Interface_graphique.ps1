Add-Type -AssemblyName System.Windows.Forms #C'est la bibliothèque pour faire les interfaces graphiques cf. cours avant dernière page

$mots = ""
$prix = $null
$hot = $null

$form = New-Object System.Windows.Forms.Form
$form.Text = "Recherche Dealabs"
$form.Width = 400
$form.Height = 250
$form.StartPosition = "CenterScreen"

$labelMot = New-Object System.Windows.Forms.Label
$labelMot.Text = "Mot a rechercher :"
$labelMot.Left = 20
$labelMot.Top = 20
$labelMot.Width = 120

$textMot = New-Object System.Windows.Forms.TextBox
$textMot.Left = 160
$textMot.Top = 20
$textMot.Width = 180

$labelPrix = New-Object System.Windows.Forms.Label
$labelPrix.Text = "Prix max :"
$labelPrix.Left = 20
$labelPrix.Top = 60
$labelPrix.Width = 120

$textPrix = New-Object System.Windows.Forms.TextBox
$textPrix.Left = 160
$textPrix.Top = 60
$textPrix.Width = 180

$labelHot = New-Object System.Windows.Forms.Label
$labelHot.Text = "Hot minimum :"
$labelHot.Left = 20
$labelHot.Top = 100
$labelHot.Width = 120

$comboHot = New-Object System.Windows.Forms.ComboBox
$comboHot.Left = 160
$comboHot.Top = 100
$comboHot.Width = 180

$comboHot.Items.Add(">20") | Out-Null
$comboHot.Items.Add(">100") | Out-Null
$comboHot.Items.Add(">500") | Out-Null

$comboHot.SelectedIndex = 0

$button = New-Object System.Windows.Forms.Button
$button.Text = "Valider"
$button.Left = 160
$button.Top = 150
$button.Width = 100

$button.Add_Click({

    $mots = $textMot.Text -replace " ", "+"
    $prix = $textPrix.Text
    $hot = $comboHot.SelectedItem
    $hot = $hot -replace ">", ""

    Write-Host "Mot recherché : $mots"
    Write-Host "Prix max : $prix"
    Write-Host "Hot minimum : $hot"

    $form.Close()
})

$form.Controls.Add($labelMot)
$form.Controls.Add($textMot)

$form.Controls.Add($labelPrix)
$form.Controls.Add($textPrix)

$form.Controls.Add($labelHot)
$form.Controls.Add($comboHot)

$form.Controls.Add($button)

$form.ShowDialog()