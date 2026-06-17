param(
    [string[]]$Mots = @("ssd"),
    [decimal]$PrixMax = 0,
    [int]$HotMin = 20,
    [int]$Top = 10,
    [switch]$Surveille,
    [int]$IntervalleSecondes = 300
)

# Notification Windows simple.
function Notifier {
    param([string]$Message)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $notification = New-Object System.Windows.Forms.NotifyIcon
    $notification.Icon = [System.Drawing.SystemIcons]::Information
    $notification.Visible = $true
    $notification.BalloonTipTitle = "Dealabs"
    $notification.BalloonTipText = $Message
    $notification.ShowBalloonTip(5000)

    Start-Sleep -Seconds 6
    $notification.Dispose()
}

# Cherche les promos Dealabs pour un mot.
function Chercher-Promos {
    param([string]$Mot)

    $recherche = $Mot -replace " ", "+"
    $urlRecherche = "https://www.dealabs.com/search?q=$recherche"

    try {
        $page = Invoke-WebRequest -Uri $urlRecherche -UseBasicParsing -Headers @{
            "User-Agent" = "Mozilla/5.0"
        }
    }
    catch {
        Write-Host "Impossible de lire Dealabs pour : $Mot"
        return @()
    }

    $promos = @()

    # Chaque promo est dans une balise <article>.
    $articles = [regex]::Matches($page.Content, "(?is)<article\b.*?</article>")

    foreach ($article in $articles) {
        $htmlArticle = $article.Value

        # Dealabs met les infos utiles dans data-vue3.
        $jsonTrouve = [regex]::Match($htmlArticle, "data-vue3='([^']*ThreadMainListItemNormalizer[^']*)'")
        if (-not $jsonTrouve.Success) {
            continue
        }

        try {
            $jsonTexte = [System.Net.WebUtility]::HtmlDecode($jsonTrouve.Groups[1].Value)
            $json = $jsonTexte | ConvertFrom-Json
            $deal = $json.props.thread

            if ($deal.title -notmatch [regex]::Escape($Mot)) {
                continue
            }

            $prix = $null
            if ($null -ne $deal.price) {
                $prix = [decimal]([string]$deal.price)
            }

            $hot = [int][Math]::Round([double]$deal.temperature)
            $lien = [string]$deal.shareableLink

            $lienHtml = [regex]::Match($htmlArticle, 'href=["'']([^"'']+)["'']')
            if ($lienHtml.Success) {
                $lien = [System.Net.WebUtility]::HtmlDecode($lienHtml.Groups[1].Value)
            }

            if ($lien -and $lien -notmatch "^https?://") {
                $lien = "https://www.dealabs.com$lien"
            }

            $promo = New-Object PSObject
            $promo | Add-Member NoteProperty Mot $Mot
            $promo | Add-Member NoteProperty Titre ([string]$deal.title)
            $promo | Add-Member NoteProperty Prix $prix
            $promo | Add-Member NoteProperty Hot $hot
            $promo | Add-Member NoteProperty Url $lien

            $promos += $promo
        }
        catch {
            # Si une promo bug, on passe a la suivante.
            continue
        }
    }

    return $promos
}

# Cherche tous les mots et garde les meilleures promos.
function Faire-Recherche {
    $resultats = @()

    foreach ($mot in $Mots) {
        $resultats += Chercher-Promos -Mot $mot
    }

    $resultats = $resultats | Where-Object {
        $_.Hot -ge $HotMin -and
        ($PrixMax -eq 0 -or $null -eq $_.Prix -or $_.Prix -le $PrixMax)
    }

    $resultats = $resultats | Sort-Object Hot -Descending | Select-Object -First $Top
    $resultats | Export-Csv -Path ".\resultats_dealabs.csv" -NoTypeInformation -Encoding UTF8

    return @($resultats)
}

# Affichage console classique.
function Afficher-Recherche {
    $resultats = Faire-Recherche

    if ($resultats.Count -eq 0) {
        Write-Host "Aucune promo trouvee."
        return
    }

    $resultats | Format-Table Mot, Titre, Prix, Hot -AutoSize
    Notifier "$($resultats[0].Hot) deg - $($resultats[0].Titre)"
}

# Surveillance en boucle.
function Surveiller-Dealabs {
    $promosDejaVues = @{}

    Write-Host "Surveillance lancee. CTRL+C pour arreter."

    while ($true) {
        $resultats = Faire-Recherche
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - $($resultats.Count) promo(s) trouvee(s)."

        foreach ($promo in $resultats) {
            if (-not $promosDejaVues.ContainsKey($promo.Url)) {
                $promosDejaVues[$promo.Url] = $true
                Notifier "Nouvelle promo : $($promo.Hot) deg - $($promo.Titre)"
            }
        }

        Start-Sleep -Seconds $IntervalleSecondes
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    if ($Surveille) {
        Surveiller-Dealabs
    }
    else {
        Afficher-Recherche
    }
}
